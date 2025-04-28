const std = @import("std");
const util = @import("util.zig");
const errors = @import("errors.zig");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const QueryParam = util.QueryParam;

pub const LatLng = struct {
    lat: f64,
    lng: f64,
};

pub const Bounds = struct {
    southwest: LatLng,
    northeast: LatLng,
};

pub const GeocodeOptions = struct {
    abbrv: ?bool = null,
    address_only: ?bool = null,
    add_request: ?bool = null,
    bounds: ?Bounds = null,
    countrycode: ?[]const u8 = null,
    language: ?[]const u8 = null,
    limit: ?u8 = null,
    no_annotations: ?bool = null,
    no_dedupe: ?bool = null,
    no_record: ?bool = null,
    pretty: ?bool = null,
    proximity: ?LatLng = null,
    roadinfo: ?bool = null,

    pub fn appendQueryItems(
        self: GeocodeOptions,
        list: *ArrayList(QueryParam),
        allocator: Allocator,
    ) !void {
        try util.appendQueryParamBool(list, allocator, "abbrv", self.abbrv orelse false);
        try util.appendQueryParamBool(list, allocator, "address_only", self.address_only orelse false);
        try util.appendQueryParamBool(list, allocator, "add_request", self.add_request orelse false);
        try util.appendQueryParamBool(list, allocator, "no_annotations", self.no_annotations orelse false);
        try util.appendQueryParamBool(list, allocator, "no_dedupe", self.no_dedupe orelse false);
        try util.appendQueryParamBool(list, allocator, "no_record", self.no_record orelse false);
        try util.appendQueryParamBool(list, allocator, "pretty", self.pretty orelse false);
        try util.appendQueryParamBool(list, allocator, "roadinfo", self.roadinfo orelse false);

        if (self.countrycode) |v| try util.appendQueryParam(list, allocator, "countrycode", v);
        if (self.language) |v| try util.appendQueryParam(list, allocator, "language", v);

        if (self.limit) |v| {
            var buf: [4]u8 = undefined;
            const val_str = std.fmt.bufPrint(&buf, "{d}", .{v}) catch unreachable;
            try util.appendQueryParam(list, allocator, "limit", val_str);
        }

        if (self.proximity) |v| {
            var buf: [64]u8 = undefined;
            var stream = std.io.fixedBufferStream(&buf);
            var tmp_writer = stream.writer();
            try tmp_writer.print("{d:.7},{d:.7}", .{ v.lat, v.lng });
            try util.appendQueryParam(list, allocator, "proximity", stream.getWritten());
        }

        if (self.bounds) |v| {
            var buf: [128]u8 = undefined;
            var stream = std.io.fixedBufferStream(&buf);
            var tmp_writer = stream.writer();
            try tmp_writer.print("{d:.7},{d:.7},{d:.7},{d:.7}", .{
                v.southwest.lng,
                v.southwest.lat,
                v.northeast.lng,
                v.northeast.lat,
            });
            try util.appendQueryParam(list, allocator, "bounds", stream.getWritten());
        }
    }
};