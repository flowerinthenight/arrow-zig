//!
//! generated by flatc-zig
//! binary:     src/gen/format/Schema.bfbs
//! schema:     format/Schema.fbs
//! file ident: //Schema.fbs
//! typename    Utf8
//!

const std = @import("std");
const fb = @import("flatbufferz");
const Builder = fb.Builder;

/// Unicode with UTF-8 encoding
pub const Utf8T = struct {
    pub fn Pack(rcv: Utf8T, __builder: *Builder, __pack_opts: fb.common.PackOptions) fb.common.PackError!u32 {
        _ = .{__pack_opts};
        var __tmp_offsets = std.ArrayListUnmanaged(u32){};
        defer if (__pack_opts.allocator) |alloc| __tmp_offsets.deinit(alloc);
        _ = rcv;
        try Utf8.Start(__builder);
        return Utf8.End(__builder);
    }

    pub fn UnpackTo(rcv: Utf8, t: *Utf8T, __pack_opts: fb.common.PackOptions) !void {
        _ = .{__pack_opts};
        _ = rcv;
        _ = t;
    }

    pub fn Unpack(rcv: Utf8, __pack_opts: fb.common.PackOptions) fb.common.PackError!Utf8T {
        var t = Utf8T{};
        try Utf8T.UnpackTo(rcv, &t, __pack_opts);
        return t;
    }

    pub fn deinit(self: *Utf8T, allocator: std.mem.Allocator) void {
        _ = .{ self, allocator };
    }
};

pub const Utf8 = struct {
    _tab: fb.Table,

    pub fn GetRootAs(buf: []u8, offset: u32) Utf8 {
        const n = fb.encode.read(u32, buf[offset..]);
        return Utf8.init(buf, n + offset);
    }

    pub fn GetSizePrefixedRootAs(buf: []u8, offset: u32) Utf8 {
        const n = fb.encode.read(u32, buf[offset + fb.Builder.size_u32 ..]);
        return Utf8.init(buf, n + offset + fb.Builder.size_u32);
    }

    pub fn init(bytes: []u8, pos: u32) Utf8 {
        return .{ ._tab = .{ .bytes = bytes, .pos = pos } };
    }

    pub fn Table(x: Utf8) fb.Table {
        return x._tab;
    }

    pub fn Start(__builder: *Builder) !void {
        try __builder.startObject(0);
    }
    pub fn End(__builder: *Builder) !u32 {
        return __builder.endObject();
    }

    pub fn Unpack(rcv: Utf8, __pack_opts: fb.common.PackOptions) !Utf8T {
        return Utf8T.Unpack(rcv, __pack_opts);
    }
    pub fn FinishBuffer(__builder: *Builder, root: u32) !void {
        return __builder.Finish(root);
    }

    pub fn FinishSizePrefixedBuffer(__builder: *Builder, root: u32) !void {
        return __builder.FinishSizePrefixed(root);
    }
};
