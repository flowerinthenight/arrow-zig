//!
//! generated by flatc-zig
//! binary:     src/gen/format/Schema.bfbs
//! schema:     format/Schema.fbs
//! file ident: //Schema.fbs
//! typename    RunEndEncoded
//!

const std = @import("std");
const fb = @import("flatbufferz");
const Builder = fb.Builder;

/// Contains two child arrays, run_ends and values.
/// The run_ends child array must be a 16/32/64-bit integer array
/// which encodes the indices at which the run with the value in
/// each corresponding index in the values child array ends.
/// Like list/struct types, the value array can be of any type.
pub const RunEndEncodedT = struct {
    pub fn Pack(rcv: RunEndEncodedT, __builder: *Builder, __pack_opts: fb.common.PackOptions) fb.common.PackError!u32 {
        _ = .{__pack_opts};
        var __tmp_offsets = std.ArrayListUnmanaged(u32){};
        defer if (__pack_opts.allocator) |alloc| __tmp_offsets.deinit(alloc);
        _ = rcv;
        try RunEndEncoded.Start(__builder);
        return RunEndEncoded.End(__builder);
    }

    pub fn UnpackTo(rcv: RunEndEncoded, t: *RunEndEncodedT, __pack_opts: fb.common.PackOptions) !void {
        _ = .{__pack_opts};
        _ = rcv;
        _ = t;
    }

    pub fn Unpack(rcv: RunEndEncoded, __pack_opts: fb.common.PackOptions) fb.common.PackError!RunEndEncodedT {
        var t = RunEndEncodedT{};
        try RunEndEncodedT.UnpackTo(rcv, &t, __pack_opts);
        return t;
    }

    pub fn deinit(self: *RunEndEncodedT, allocator: std.mem.Allocator) void {
        _ = .{ self, allocator };
    }
};

pub const RunEndEncoded = struct {
    _tab: fb.Table,

    pub fn GetRootAs(buf: []u8, offset: u32) RunEndEncoded {
        const n = fb.encode.read(u32, buf[offset..]);
        return RunEndEncoded.init(buf, n + offset);
    }

    pub fn GetSizePrefixedRootAs(buf: []u8, offset: u32) RunEndEncoded {
        const n = fb.encode.read(u32, buf[offset + fb.Builder.size_u32 ..]);
        return RunEndEncoded.init(buf, n + offset + fb.Builder.size_u32);
    }

    pub fn init(bytes: []u8, pos: u32) RunEndEncoded {
        return .{ ._tab = .{ .bytes = bytes, .pos = pos } };
    }

    pub fn Table(x: RunEndEncoded) fb.Table {
        return x._tab;
    }

    pub fn Start(__builder: *Builder) !void {
        try __builder.startObject(0);
    }
    pub fn End(__builder: *Builder) !u32 {
        return __builder.endObject();
    }

    pub fn Unpack(rcv: RunEndEncoded, __pack_opts: fb.common.PackOptions) !RunEndEncodedT {
        return RunEndEncodedT.Unpack(rcv, __pack_opts);
    }
    pub fn FinishBuffer(__builder: *Builder, root: u32) !void {
        return __builder.Finish(root);
    }

    pub fn FinishSizePrefixedBuffer(__builder: *Builder, root: u32) !void {
        return __builder.FinishSizePrefixed(root);
    }
};
