//!
//! generated by flatc-zig
//! binary:     src/gen/format/Schema.bfbs
//! schema:     format/Schema.fbs
//! file ident: //Schema.fbs
//! typename    LargeBinary
//!

const std = @import("std");
const fb = @import("flatbufferz");
const Builder = fb.Builder;

/// Same as Binary, but with 64-bit offsets, allowing to represent
/// extremely large data values.
pub const LargeBinaryT = struct {
    pub fn Pack(rcv: LargeBinaryT, __builder: *Builder, __pack_opts: fb.common.PackOptions) fb.common.PackError!u32 {
        _ = .{__pack_opts};
        var __tmp_offsets = std.ArrayListUnmanaged(u32){};
        defer if (__pack_opts.allocator) |alloc| __tmp_offsets.deinit(alloc);
        _ = rcv;
        try LargeBinary.Start(__builder);
        return LargeBinary.End(__builder);
    }

    pub fn UnpackTo(rcv: LargeBinary, t: *LargeBinaryT, __pack_opts: fb.common.PackOptions) !void {
        _ = .{__pack_opts};
        _ = rcv;
        _ = t;
    }

    pub fn Unpack(rcv: LargeBinary, __pack_opts: fb.common.PackOptions) fb.common.PackError!LargeBinaryT {
        var t = LargeBinaryT{};
        try LargeBinaryT.UnpackTo(rcv, &t, __pack_opts);
        return t;
    }

    pub fn deinit(self: *LargeBinaryT, allocator: std.mem.Allocator) void {
        _ = .{ self, allocator };
    }
};

pub const LargeBinary = struct {
    _tab: fb.Table,

    pub fn GetRootAs(buf: []u8, offset: u32) LargeBinary {
        const n = fb.encode.read(u32, buf[offset..]);
        return LargeBinary.init(buf, n + offset);
    }

    pub fn GetSizePrefixedRootAs(buf: []u8, offset: u32) LargeBinary {
        const n = fb.encode.read(u32, buf[offset + fb.Builder.size_u32 ..]);
        return LargeBinary.init(buf, n + offset + fb.Builder.size_u32);
    }

    pub fn init(bytes: []u8, pos: u32) LargeBinary {
        return .{ ._tab = .{ .bytes = bytes, .pos = pos } };
    }

    pub fn Table(x: LargeBinary) fb.Table {
        return x._tab;
    }

    pub fn Start(__builder: *Builder) !void {
        try __builder.startObject(0);
    }
    pub fn End(__builder: *Builder) !u32 {
        return __builder.endObject();
    }

    pub fn Unpack(rcv: LargeBinary, __pack_opts: fb.common.PackOptions) !LargeBinaryT {
        return LargeBinaryT.Unpack(rcv, __pack_opts);
    }
    pub fn FinishBuffer(__builder: *Builder, root: u32) !void {
        return __builder.Finish(root);
    }

    pub fn FinishSizePrefixedBuffer(__builder: *Builder, root: u32) !void {
        return __builder.FinishSizePrefixed(root);
    }
};
