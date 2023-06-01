// Flat means no children. Includes Primitive, VariableBinary, and FixedBinary layouts.
const std = @import("std");
const tags = @import("../tags.zig");
const array = @import("./array.zig");
const abi = @import("../abi.zig");

pub fn BuilderAdvanced(comptime T: type, comptime opts: tags.BinaryOptions) type {
	const tag = tags.Tag.fromPrimitive(T, opts);
	const layout = tag.abiLayout();
	if (layout != .Primitive and layout != .VariableBinary) {
		@compileError("unsupported flat type " ++ @typeName(T));
	}
	const is_fixed = tag == .FixedBinary;
	const fixed_len = if (is_fixed) tag.FixedBinary.fixed_len else 0;
	if (is_fixed and fixed_len < 1) {
		@compileError(std.fmt.comptimePrint("expected fixed_len >= 1, got {d}", .{ fixed_len }));
	}

	const NullCount = if (@typeInfo(T) == .Optional) usize else void;
	const ValidityList = if (@typeInfo(T) == .Optional) std.bit_set.DynamicBitSet else void;
	const ValueType = tag.Primitive();

	const OffsetType = if (opts.large) i64 else i32;
	const OffsetList = if (layout.hasOffsets()) std.ArrayListAligned(OffsetType, array.BufferAlignment) else void;
	const ValueList = std.ArrayListAligned(ValueType, array.BufferAlignment);

	return struct {
		const Self = @This();

		null_count: NullCount,
		validity: ValidityList,
		offsets: OffsetList,
		values: ValueList,

		pub fn Type() type {
			return T;
		}

		pub fn init(allocator: std.mem.Allocator) !Self {
			var res = Self {
				.null_count = if (NullCount != void) 0 else {},
				.validity = if (ValidityList != void) try ValidityList.initEmpty(allocator, 0) else {},
				.offsets = if (OffsetList != void) OffsetList.init(allocator) else {},
				.values = ValueList.init(allocator),
			};
			// dunno why this is in the spec:
			// > the offsets buffer contains length + 1 signed integers (either 32-bit or 64-bit,
			// > depending on the logical type), which encode the start position of each slot in the data
			// > buffer.
			if (OffsetList != void) {
				try res.offsets.append(0);
			}

			return res;
		}

		pub fn deinit(self: *Self) void {
			if (ValidityList != void) self.validity.deinit();
			if (OffsetList != void) self.offsets.deinit();
			self.values.deinit();
		}

		fn appendAny(self: *Self, value: anytype) std.mem.Allocator.Error!void {
			switch (@typeInfo(@TypeOf(value))) {
				.Bool, .Int, .Float, .ComptimeInt, .ComptimeFloat => try self.values.append(value),
				.Pointer => |p| switch (p.size) {
					.Slice => {
						std.debug.assert(layout == .VariableBinary);
						try self.values.appendSlice(value);
						try self.offsets.append(@intCast(OffsetType, self.values.items.len));
					},
					else => |t| @compileError("unsupported pointer type " ++ @tagName(t)),
				},
				.Array => |a| {
					std.debug.assert(is_fixed);
					if (a.len != fixed_len)
						@compileError(std.fmt.comptimePrint(
								"expected array of len {d} but got array of len {d}", .{ fixed_len, a.len }
						));
					try self.values.appendSlice(&value);
				},
				.Null => {
					if (OffsetList != void) {
						try self.offsets.append(self.offsets.getLast());
					} else {
						// > Array slots which are null are not required to have a particular value; any
						// > "masked" memory can have any value and need not be zeroed, though implementations
						// > frequently choose to zero memory for null items.
						// PLEASE, for the sake of SIMD, 0 this
						if (comptime is_fixed) {
							for (0..fixed_len) |_| try self.appendAny(0);
						} else {
							try self.appendAny(0);
						}
					}
				},
				.Optional => {
					const is_null = value == null;
					try self.validity.resize(self.validity.capacity() + 1, !is_null);
					if (is_null) {
						self.null_count += 1;
						try self.appendAny(null);
					} else {
						try self.appendAny(value.?);
					}
				},
				else => |t| @compileError("unsupported append type " ++ @tagName(t))
			}
		}

		pub fn append(self: *Self, value: T) std.mem.Allocator.Error!void {
			return self.appendAny(value);
		}

		fn makeBufs(self: *Self) ![3][]align(abi.BufferAlignment) u8 {
			const allocator = self.values.allocator;
			return switch (comptime layout) {
				.Primitive => .{
					if (ValidityList != void)
						try array.validity(allocator, &self.validity, self.null_count)
					else &.{},
					std.mem.sliceAsBytes(try self.values.toOwnedSlice()),
					&.{},
				},
				.VariableBinary => .{
					if (ValidityList != void)
						try array.validity(allocator, &self.validity, self.null_count)
					else &.{},
					if (OffsetList != void)
						std.mem.sliceAsBytes(try self.offsets.toOwnedSlice())
					else &.{},
					std.mem.sliceAsBytes(try self.values.toOwnedSlice()),
				},
				else => @compileError("should have checked layout earlier"),
			};
		}

		fn len(self: *Self) usize {
			if (OffsetList != void) return self.offsets.items.len - 1;
			var res = self.values.items.len;
			if (comptime is_fixed) res /= @intCast(usize, fixed_len);
			return res;
		}

		pub fn finish(self: *Self) !*array.Array {
			const allocator = self.values.allocator;
			var res = try array.Array.init(allocator);
			res.* = .{
				.tag = tag,
				.name = @typeName(T) ++ " builder",
				.allocator = allocator,
				.length = self.len(),
				.null_count = if (NullCount != void) self.null_count else 0,
				.bufs = try self.makeBufs(),
				.children = &.{}
			};
			return res;
		}
	};
}

pub fn Builder(comptime T: type) type {
	return BuilderAdvanced(T, .{ .large = false, .utf8 = false });
}

test "primitive init + deinit" {
	var b = try Builder(i32).init(std.testing.allocator);
	defer b.deinit();

	try b.append(32);
}

const MaskInt = std.bit_set.DynamicBitSet.MaskInt;
test "primitive optional" {
	var b = try Builder(?i32).init(std.testing.allocator);
	defer b.deinit();
	try b.append(1);
	try b.append(null);
	try b.append(2);
	try b.append(4);

	const masks = b.validity.unmanaged.masks;
	try std.testing.expectEqual(@as(MaskInt, 0b1101), masks[0]);
}

test "primitive finish" {
	const T = i32;
	var b = try Builder(?T).init(std.testing.allocator);
	try b.append(1);
	try b.append(null);
	try b.append(2);
	try b.append(4);

	var a = try b.finish();
	defer a.deinit();

	const masks = a.bufs[0];
	try std.testing.expectEqual(@as(u8, 0b1101), masks[0]);

	const values = std.mem.bytesAsSlice(T, a.bufs[1]);
	try std.testing.expectEqualSlices(T, &[_]T{ 1, 0, 2, 4 }, values);

	const tag = tags.Tag{
		.Int = tags.IntOptions{
			.nullable = true,
			.signed = true,
			.bit_width = ._32
		}
	};
	try std.testing.expectEqual(tag, a.tag);
}

test "varbinary init + deinit" {
	var b = try Builder([]const u8).init(std.testing.allocator);
	defer b.deinit();

	try b.append(&[_]u8{1,2,3});
}

test "varbinary utf8" {
	var b = try BuilderAdvanced([]const u8, .{ .large = true, .utf8 = true }).init(std.testing.allocator);
	defer b.deinit();

	try b.append(&[_]u8{1,2,3});
}

test "varbinary optional" {
	var b = try Builder(?[]const u8).init(std.testing.allocator);
	defer b.deinit();
	try b.append(null);
	try b.append(&[_]u8{1,2,3});

	const masks = b.validity.unmanaged.masks;
	try std.testing.expectEqual(@as(MaskInt, 0b10), masks[0]);
}

test "varbinary finish" {
	var b = try Builder(?[]const u8).init(std.testing.allocator);
	const s = "hello";
	try b.append(null);
	try b.append(s);

	var a = try b.finish();
	defer a.deinit();

	try std.testing.expectEqual(@as(u8, 0b10), a.bufs[0][0]);
	const offsets = std.mem.bytesAsSlice(i32, a.bufs[1]);
	try std.testing.expectEqualSlices(i32, &[_]i32{0, 0, s.len}, offsets);
	try std.testing.expectEqualStrings(s, a.bufs[2][0..s.len]);
}

test "c abi" {
	var b = try Builder(?[]const u8).init(std.testing.allocator);
	try b.append(null);
	try b.append("hello");

	var a = try b.finish();
	var c = try a.toOwnedAbi();
	defer c.release.?(@constCast(&c));

	const buf0 = @constCast(c.buffers.?[0].?);
	try std.testing.expectEqual(@as(u8, 0b10), @ptrCast([*]u8, buf0)[0]);
	try std.testing.expectEqual(@as(i64, 1), c.null_count);

	const buf1 = @constCast(c.buffers.?[1].?);
	const offsets = @ptrCast([*]i32, @alignCast(@alignOf(i32), buf1));
	try std.testing.expectEqual(@as(i32, 0), offsets[0]);
	try std.testing.expectEqual(@as(i32, 0), offsets[1]);
	try std.testing.expectEqual(@as(i32, 5), offsets[2]);

	const buf2 = @constCast(c.buffers.?[2].?);
	const values = @ptrCast([*]u8, buf2);
	try std.testing.expectEqualStrings("hello", values[0..5]);

	var cname = "c1";
	a.name = cname;
	var s = try a.ownedSchema();
	defer s.release.?(@constCast(&s));
	try std.testing.expectEqualStrings(cname, s.name.?[0..cname.len]);
}

test "fixed binary finish" {
	var b = try Builder(?[3]u8).init(std.testing.allocator);
	try b.append(null);
	const s = "hey";
	try b.append(std.mem.sliceAsBytes(s)[0..s.len].*);

	var a = try b.finish();
	defer a.deinit();

	try std.testing.expectEqual(@as(u8, 0b10), a.bufs[0][0]);
	try std.testing.expectEqualStrings("\x00" ** s.len ++ s, a.bufs[1]);
	try std.testing.expectEqual(@as(usize, 0), a.bufs[2].len);
}
