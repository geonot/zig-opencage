const std = @import("std");
const errors = @import("errors.zig");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

pub const QueryParam = struct {
    key: []const u8,
    value: ?[]const u8 = null,
};

pub fn formatFloat(buf: []u8, value: f64, precision: u8) ![]u8 {
    const safe_precision = @min(precision, 15);
    var fmt_buf: [5]u8 = undefined;
    const fmt_str = try std.fmt.bufPrint(&fmt_buf, "{{d:.{}}}", .{safe_precision});

    return std.fmt.bufPrint(buf, fmt_str, .{value}) catch |err| switch (err) {
        error.NoSpaceLeft => errors.ErrorCode.BufferTooSmall,
        else => |other_err| return other_err,
    };
}

pub fn appendQueryParam(
    list: *ArrayList(QueryParam),
    allocator: Allocator,
    key: []const u8,
    value_str: []const u8,
) !void {
    const key_copy = allocator.dupe(u8, key) catch return error.AllocationFailed;
    errdefer allocator.free(key_copy);
    const value_copy = allocator.dupe(u8, value_str) catch return error.AllocationFailed;
    errdefer allocator.free(value_copy);

    list.append(.{ .key = key_copy, .value = value_copy }) catch {
        allocator.free(key_copy);
        allocator.free(value_copy);
        return error.AllocationFailed;
    };
}

pub fn appendQueryParamBool(
    list: *ArrayList(QueryParam),
    allocator: Allocator,
    key: []const u8,
    value: bool,
) !void {
    if (value) {
        try appendQueryParam(list, allocator, key, "1");
    }
}

pub fn buildQueryString(
    allocator: Allocator,
    base_query: []const u8,
    params: []const QueryParam,
) ![]u8 {
    var result = std.ArrayList(u8).init(allocator);
    errdefer result.deinit();

    if (base_query.len > 0) {
        try result.appendSlice(base_query);
    }

    for (params, 0..) |param, i| {
        const separator = if (base_query.len == 0 and i == 0) "?" else "&";
        try result.appendSlice(separator);

        try urlEncodeInto(param.key, &result);

        if (param.value) |value| {
            try result.append('=');
            try urlEncodeInto(value, &result);
        }
    }
    return result.toOwnedSlice() catch return error.AllocationFailed;
}

fn urlEncodeInto(input: []const u8, output: *std.ArrayList(u8)) !void {
    const hex_chars = "0123456789ABCDEF";
    for (input) |byte| {
        switch (byte) {
            'a'...'z', 'A'...'Z', '0'...'9', '-', '.', '_', '~' => try output.append(byte),
            ' ' => try output.append('+'),
            else => {
                try output.append('%');
                try output.append(hex_chars[byte >> 4]);
                try output.append(hex_chars[byte & 0x0F]);
            },
        }
    }
}

/// Safely writes a UTF-8 string to a writer without interpreting it as a format string.
/// Handles null or empty strings gracefully by printing informative placeholders.
pub fn safeWriteUtf8(writer: anytype, str: []const u8) !void {
    if (str.len == 0) {
        try writer.writeAll("[Empty String]");
        return;
    }
    try writer.writeAll(str);
}

/// Safely writes an optional UTF-8 string to a writer.
/// Handles null pointers by printing an informative placeholder.
pub fn safeWriteUtf8Optional(writer: anytype, str: ?[]const u8) !void {
    if (str) |s| {
        try safeWriteUtf8(writer, s);
    } else {
        try writer.writeAll("[No Data]");
    }
}

test "formatFloat" {
    var buf: [32]u8 = undefined;
    var res = try formatFloat(&buf, 123.456789, 4);
    try std.testing.expectEqualStrings("123.4568", res);

    res = try formatFloat(&buf, -0.123, 7);
    try std.testing.expectEqualStrings("-0.1230000", res);

    res = try formatFloat(&buf, 99.0, 0);
    try std.testing.expectEqualStrings("99", res);

    const small_buf: [4]u8 = undefined;
    try std.testing.expectError(errors.ErrorCode.BufferTooSmall, formatFloat(&small_buf, 123.45, 1));
}

test "appendQueryParam and appendQueryParamBool" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    var list = ArrayList(QueryParam).init(allocator);
    defer {
        for (list.items) |item| {
            allocator.free(item.key);
            if (item.value) |v| allocator.free(v);
        }
        list.deinit();
    }

    try appendQueryParam(&list, allocator, "city", "Berlin");
    try appendQueryParamBool(&list, allocator, "pretty", true);
    try appendQueryParamBool(&list, allocator, "abbrv", false);

    try std.testing.expectEqual(@as(usize, 2), list.items.len);
    try std.testing.expectEqualStrings("city", list.items[0].key);
    try std.testing.expectEqualStrings("Berlin", list.items[0].value.?);
    try std.testing.expectEqualStrings("pretty", list.items[1].key);
    try std.testing.expectEqualStrings("1", list.items[1].value.?);
}

test "safeWriteUtf8 and safeWriteUtf8Optional" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var buffer = std.ArrayList(u8).init(allocator);
    defer buffer.deinit();
    const writer = buffer.writer();

    try safeWriteUtf8(writer, "Hello Müller");
    try std.testing.expectEqualStrings("Hello Müller", buffer.items);
    buffer.clearRetainingCapacity();

    try safeWriteUtf8(writer, "");
    try std.testing.expectEqualStrings("[Empty String]", buffer.items);
    buffer.clearRetainingCapacity();

    try safeWriteUtf8Optional(writer, "Some Data");
    try std.testing.expectEqualStrings("Some Data", buffer.items);
    buffer.clearRetainingCapacity();

    const null_str: ?[]const u8 = null;
    try safeWriteUtf8Optional(writer, null_str);
    try std.testing.expectEqualStrings("[No Data]", buffer.items);
    buffer.clearRetainingCapacity();

    const empty_str: ?[]const u8 = "";
    try safeWriteUtf8Optional(writer, empty_str);
    try std.testing.expectEqualStrings("[Empty String]", buffer.items);
    buffer.clearRetainingCapacity();
}

test "buildQueryString encoding" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var params_list = std.ArrayList(QueryParam).init(allocator);
    defer {
        for (params_list.items) |item| {
            allocator.free(item.key);
            if (item.value) |v| allocator.free(v);
        }
        params_list.deinit();
    }

    try appendQueryParam(params_list, allocator, "q", "New York");
    try appendQueryParam(params_list, allocator, "special&", "a=b c");
    try appendQueryParam(params_list, allocator, "nokey", ""); // Append key with empty value
    try params_list.append(.{ .key = try allocator.dupe(u8, "keyonly"), .value = null }); // Key only param (allocator manages key)

    const query = try buildQueryString(allocator, "", params_list.items);
    defer allocator.free(query);

    const expected = "?q=New+York&special%26=a%3Db+c&nokey=&keyonly";
    try std.testing.expectEqualStrings(expected, query);

    const query_with_base = try buildQueryString(allocator, "base=1", params_list.items);
    defer allocator.free(query_with_base);
    const expected_with_base = "base=1&q=New+York&special%26=a%3Db+c&nokey=&keyonly";
    try std.testing.expectEqualStrings(expected_with_base, query_with_base);
}
