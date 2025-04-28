const std = @import("std");
const errors = @import("errors.zig");
const options_mod = @import("options.zig");
const response_mod = @import("response.zig");
const util = @import("util.zig");

const Allocator = std.mem.Allocator;
const Error = errors.ErrorCode;
const ApiResponse = response_mod.ApiResponse;
const GeocodeOptions = options_mod.GeocodeOptions;
const LatLng = options_mod.LatLng;
const Bounds = options_mod.Bounds;
const QueryParam = util.QueryParam;

const API_HOST = "api.opencagedata.com";
const API_PATH = "/geocode/v1/json";
const API_SCHEME = "https";
const SDK_VERSION = "0.1.0";

pub const Client = struct {
    allocator: Allocator,
    api_key: []const u8,
    http_client: std.http.Client,
    user_agent: []const u8,

    pub fn init(
        allocator: Allocator,
        api_key: []const u8,
    ) !@This() {
        if (api_key.len == 0) return Error.InvalidApiKey;

        var success = false;
        const key_copy = allocator.dupe(u8, api_key) catch return Error.AllocationFailed;

        defer if (!success) allocator.free(key_copy);

        const user_agent_str = std.fmt.allocPrint(allocator, "zig-opencage-sdk/{s}", .{SDK_VERSION}) catch return Error.AllocationFailed;
        defer if (!success) allocator.free(user_agent_str);

        const http_client = std.http.Client{
            .allocator = allocator,
        };

        success = true;
        return @This(){
            .allocator = allocator,
            .api_key = key_copy,
            .http_client = http_client,
            .user_agent = user_agent_str,
        };
    }

    pub fn deinit(self: *@This()) void {
        self.http_client.deinit();
        self.allocator.free(self.api_key);
        self.allocator.free(self.user_agent);
        self.* = undefined;
    }

    pub fn geocodeForward(
        self: *@This(),
        query: []const u8,
        opts: ?GeocodeOptions,
    ) !std.json.Parsed(ApiResponse) {
        var params = std.ArrayList(QueryParam).init(self.allocator);
        defer self.deinitParams(&params);

        try util.appendQueryParam(&params, self.allocator, "key", self.api_key);

        if (query.len < 2) return Error.BadRequest;
        try util.appendQueryParam(&params, self.allocator, "q", query);

        if (opts) |options_val| {
            try options_val.appendQueryItems(&params, self.allocator);
        }

        return self.performRequest(&params);
    }

    pub fn geocodeReverse(
        self: *@This(),
        latitude: f64,
        longitude: f64,
        opts: ?GeocodeOptions,
    ) !std.json.Parsed(ApiResponse) {
        var params = std.ArrayList(QueryParam).init(self.allocator);
        defer self.deinitParams(&params);

        try util.appendQueryParam(&params, self.allocator, "key", self.api_key);

        var coord_buf: [128]u8 = undefined;
        const q_value = try std.fmt.bufPrint(&coord_buf, "{d:.7},{d:.7}", .{ latitude, longitude });
        try util.appendQueryParam(&params, self.allocator, "q", q_value);

        if (opts) |options_val| {
            try options_val.appendQueryItems(&params, self.allocator);
        }

        return self.performRequest(&params);
    }

    fn deinitParams(self: *@This(), params: *std.ArrayList(QueryParam)) void {
        for (params.items) |param| {
            self.allocator.free(param.key);
            if (param.value) |v| self.allocator.free(v);
        }
        params.deinit();
    }

    fn performRequest(
        self: *@This(),
        params: *const std.ArrayList(QueryParam),
    ) !std.json.Parsed(ApiResponse) {
        const query_str = try util.buildQueryString(self.allocator, "", params.items);
        defer self.allocator.free(query_str);

        const uri = std.Uri{
            .scheme = API_SCHEME,
            .host = .{ .percent_encoded = API_HOST },
            .path = .{ .percent_encoded = API_PATH },
            .query = .{ .percent_encoded = if (query_str.len > 0 and query_str[0] == '?')
                query_str[1..]
            else
                query_str },
            .user = null,
            .password = null,
            .port = null,
            .fragment = null,
        };

        const headers = std.http.Client.Request.Headers{
            .user_agent = .{ .override = self.user_agent },
            .accept_encoding = .default,
            .connection = .default,
            .content_type = .omit,
            .host = .default,
            .authorization = .default,
        };

        var response_body = std.ArrayList(u8).init(self.allocator);
        defer response_body.deinit();

        const result = self.http_client.fetch(.{
            .method = .GET,
            .location = .{ .uri = uri },
            .headers = headers,
            .response_storage = .{ .dynamic = &response_body },
            .max_append_size = 10 * 1024 * 1024,
        }) catch |err| {
            std.log.err("HTTP fetch failed: {any}", .{err});
            return switch (err) {
                error.HttpHeadersOversize => Error.HttpError,
                error.TooManyHttpRedirects => Error.HttpError,
                error.ConnectionRefused, error.NetworkUnreachable, error.ConnectionTimedOut, error.ConnectionResetByPeer, error.TemporaryNameServerFailure, error.NameServerFailure, error.UnknownHostName, error.HostLacksNetworkAddresses, error.UnexpectedConnectFailure, error.UnexpectedReadFailure => Error.NetworkError,
                error.TlsInitializationFailed, error.TlsFailure, error.TlsAlert => Error.NetworkError,
                error.UriMissingHost, error.UnsupportedUriScheme => Error.InvalidUrl,
                error.OutOfMemory => Error.AllocationFailed,
                else => Error.NetworkError,
            };
        };

        const status = result.status;
        if (@intFromEnum(status) < 200 or @intFromEnum(status) >= 300) {
            std.log.err("HTTP request failed with status: {s} ({d})", .{ @tagName(status), @intFromEnum(status) });

            if (response_body.items.len > 0) {
                const log_len = @min(response_body.items.len, 1024);
                std.log.info("Error Response Body (up to {d} bytes): {s}", .{ log_len, response_body.items[0..log_len] });
            }

            return switch (status) {
                .bad_request => Error.BadRequest,
                .unauthorized => Error.InvalidApiKey,
                .payment_required => Error.QuotaExceeded,
                .forbidden => Error.Forbidden,
                .not_found => Error.InvalidUrl,
                .request_timeout => Error.NetworkError,
                .gone => Error.RequestTooLong,
                .payload_too_large => Error.RequestTooLong,
                .uri_too_long => Error.InvalidUrl,
                .too_many_requests => Error.RateLimited,
                .internal_server_error,
                .bad_gateway,
                .service_unavailable,
                .gateway_timeout,
                .http_version_not_supported,
                => Error.ServerError,
                else => Error.HttpError,
            };
        }

        var parsed_response = response_mod.parseResponse(self.allocator, response_body.items) catch |parse_err| {
            return parse_err;
        };

        var success_after_parse = false;
        defer if (!success_after_parse) parsed_response.deinit();

        if (parsed_response.value.status.code != 200) {
            std.log.warn("API returned HTTP {s} but internal status code {d}: {s}", .{
                @tagName(status), parsed_response.value.status.code, parsed_response.value.status.message,
            });
            return switch (parsed_response.value.status.code) {
                400 => Error.BadRequest,
                401 => Error.InvalidApiKey,
                402 => Error.QuotaExceeded,
                403 => Error.Forbidden,
                404 => Error.InvalidUrl,
                408 => Error.NetworkError,
                410 => Error.RequestTooLong,
                413 => Error.RequestTooLong,
                414 => Error.InvalidUrl,
                429 => Error.RateLimited,
                500...599 => Error.ServerError,
                else => Error.ApiResponseError,
            };
        }

        success_after_parse = true;
        return parsed_response;
    }
};

fn getTestApiKey(allocator: Allocator, key_name: []const u8) !?[]const u8 {
    return std.process.getEnvVarOwned(allocator, key_name) catch |err| switch (err) {
        error.EnvironmentVariableNotFound => return null,
        else => |e| return e,
    };
}

fn skipTestIfKeyMissing(key: ?[]const u8, key_name: []const u8) void {
    if (key == null) {
        std.debug.print("Skipping test: Environment variable {s} not set.\n", .{key_name});
    }
}

test "Integration: Forward Geocode OK" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const key = try getTestApiKey(allocator, "OPENCAGE_TEST_KEY_OK") orelse {
        std.debug.print("Skipping test: Environment variable OPENCAGE_TEST_KEY_OK not set.\n", .{});
        return;
    };
    defer allocator.free(key);

    var client = try Client.init(allocator, key);
    defer client.deinit();

    var result = try client.geocodeForward("Doesn't matter, test key overrides", .{});
    defer result.deinit();

    try std.testing.expectEqual(@as(u16, 200), result.value.status.code);
    try std.testing.expect(result.value.total_results > 0);
    try std.testing.expectEqualStrings("Münster", result.value.results[0].components.city.?);
}

test "Integration: Reverse Geocode OK" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const key = try getTestApiKey(allocator, "OPENCAGE_TEST_KEY_OK") orelse {
        std.debug.print("Skipping test: Environment variable OPENCAGE_TEST_KEY_OK not set.\n", .{});
        return;
    };
    defer allocator.free(key);

    var client = try Client.init(allocator, key);
    defer client.deinit();

    var result = try client.geocodeReverse(51.952659, 7.632473, .{ .language = "de" });
    defer result.deinit();

    try std.testing.expectEqual(@as(u16, 200), result.value.status.code);
    try std.testing.expect(result.value.total_results > 0);
    try std.testing.expectEqualStrings("Münster", result.value.results[0].components.city.?);
    try std.testing.expectEqualStrings("Nordrhein-Westfalen", result.value.results[0].components.state.?);
}

test "Integration: Forward Geocode No Results" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const key = try getTestApiKey(allocator, "OPENCAGE_TEST_KEY_OK") orelse {
        std.debug.print("Skipping test: Environment variable OPENCAGE_TEST_KEY_OK not set.\n", .{});
        return;
    };
    defer allocator.free(key);

    var client = try Client.init(allocator, key);
    defer client.deinit();

    var result = try client.geocodeForward("NOWHERE-INTERESTING", .{});
    defer result.deinit();

    try std.testing.expectEqual(@as(u16, 200), result.value.status.code);
    try std.testing.expectEqual(@as(usize, 0), result.value.total_results);
    try std.testing.expectEqual(@as(usize, 0), result.value.results.len);
}

test "Integration: Error 402 - Quota Exceeded" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const key = try getTestApiKey(allocator, "OPENCAGE_TEST_KEY_402") orelse {
        std.debug.print("Skipping test: Environment variable OPENCAGE_TEST_KEY_402 not set.\n", .{});
        return;
    };
    defer allocator.free(key);

    var client = try Client.init(allocator, key);
    defer client.deinit();

    const result = client.geocodeForward("query", .{});
    try std.testing.expectError(Error.QuotaExceeded, result);
}

test "Integration: Error 403 - Disabled Key" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const key = try getTestApiKey(allocator, "OPENCAGE_TEST_KEY_403_DISABLED") orelse {
        std.debug.print("Skipping test: Environment variable OPENCAGE_TEST_KEY_403_DISABLED not set.\n", .{});
        return;
    };
    defer allocator.free(key);

    var client = try Client.init(allocator, key);
    defer client.deinit();

    const result = client.geocodeForward("query", .{});
    try std.testing.expectError(Error.Forbidden, result);
}

test "Integration: Error 403 - IP Rejected" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const key = try getTestApiKey(allocator, "OPENCAGE_TEST_KEY_403_IP") orelse {
        std.debug.print("Skipping test: Environment variable OPENCAGE_TEST_KEY_403_IP not set.\n", .{});
        return;
    };
    defer allocator.free(key);

    var client = try Client.init(allocator, key);
    defer client.deinit();

    const result = client.geocodeForward("query", .{});
    try std.testing.expectError(Error.Forbidden, result);
}

test "Integration: Error 429 - Rate Limited" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const key = try getTestApiKey(allocator, "OPENCAGE_TEST_KEY_429") orelse {
        std.debug.print("Skipping test: Environment variable OPENCAGE_TEST_KEY_429 not set.\n", .{});
        return;
    };
    defer allocator.free(key);

    var client = try Client.init(allocator, key);
    defer client.deinit();

    const result = client.geocodeForward("query", .{});
    try std.testing.expectError(Error.RateLimited, result);
}

test "Integration: Error 401 - Invalid Key (Simulated by empty string)" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const result = Client.init(allocator, "");
    // Init should catch empty key now
    try std.testing.expectError(Error.InvalidApiKey, result);

    // Test with a non-empty but likely invalid key (API should return 401)
    var client = try Client.init(allocator, "this-is-not-a-real-api-key");
    defer client.deinit();
    const geocode_result = client.geocodeForward("query", .{});
    try std.testing.expectError(Error.InvalidApiKey, geocode_result);
}

test "Integration: Error 400 - Bad Request (Query too short)" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const key = try getTestApiKey(allocator, "OPENCAGE_TEST_KEY_OK") orelse {
        std.debug.print("Skipping test: Environment variable OPENCAGE_TEST_KEY_OK not set.\n", .{});
        return;
    };
    defer allocator.free(key);

    var client = try Client.init(allocator, key);
    defer client.deinit();

    const result = client.geocodeForward("q", .{}); // Query "q" is too short
    try std.testing.expectError(Error.BadRequest, result);
}
