const std = @import("std");
const opencage = @import("opencage");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const leaked = gpa.deinit();
        if (leaked == .leak) {
            std.debug.print("Memory leaks detected!\n", .{});
            std.process.exit(1);
        }
    }
    const allocator = gpa.allocator();

    const stdout = std.io.getStdOut().writer();
    const stderr = std.io.getStdErr().writer();

    const api_key = std.process.getEnvVarOwned(allocator, "OPENCAGE_API_KEY") catch |err| {
        try stderr.print("Error getting OPENCAGE_API_KEY: {s}\n", .{@errorName(err)});
        try stderr.print("Please set the OPENCAGE_API_KEY environment variable.\n", .{});
        std.process.exit(1);
    };
    defer allocator.free(api_key);

    var client = opencage.Client.init(allocator, api_key) catch |err| {
        try stderr.print("Failed to initialize OpenCage client: {s}\n", .{@errorName(err)});
        std.process.exit(1);
    };
    defer client.deinit();

    const query = "Brandenburg Gate, Berlin";
    const opts: opencage.GeocodeOptions = .{
        .limit = 1,
        .language = "en",
    };

    try stdout.print("Forward Geocoding Query: '{s}'\nOptions: {any}\n\n", .{ query, opts });

    var parsed_response = client.geocodeForward(query, opts) catch |err| {
        try stderr.print("Forward geocoding request failed: {s}\n", .{@errorName(err)});
        switch (err) {
            opencage.Error.InvalidApiKey => try stderr.print(" -> Check if OPENCAGE_API_KEY is valid.\n", .{}),
            opencage.Error.QuotaExceeded => try stderr.print(" -> API Quota Exceeded.\n", .{}),
            opencage.Error.BadRequest => try stderr.print(" -> Bad Request (check query format or parameters).\n", .{}),
            opencage.Error.Forbidden => try stderr.print(" -> Forbidden (key disabled or IP rejected).\n", .{}),
            opencage.Error.RateLimited => try stderr.print(" -> Rate Limited (too many requests).\n", .{}),
            opencage.Error.RequestTooLong => try stderr.print(" -> Request query was too long.\n", .{}),
            opencage.Error.ServerError => try stderr.print(" -> OpenCage server error. Try again later.\n", .{}),
            opencage.Error.NetworkError => try stderr.print(" -> Network error communicating with OpenCage.\n", .{}),
            opencage.Error.HttpError => try stderr.print(" -> Received unexpected HTTP status from OpenCage.\n", .{}),
            opencage.Error.JsonParseError => try stderr.print(" -> Failed to parse JSON response from OpenCage.\n", .{}),
            opencage.Error.ApiResponseError => try stderr.print(" -> API reported an unspecified error in the response.\n", .{}),
            opencage.Error.InvalidUrl => try stderr.print(" -> Internal SDK error: Invalid URL constructed.\n", .{}),
            opencage.Error.AllocationFailed => try stderr.print(" -> Internal SDK error: Memory allocation failed.\n", .{}),
            opencage.Error.MissingDependency => try stderr.print(" -> Missing required system dependency (e.g., for TLS).\n", .{}),
            else => try stderr.print(" -> Unexpected error occurred.\n", .{}),
        }
        std.process.exit(1);
    };

    defer parsed_response.deinit();

    const response = parsed_response.value;

    try stdout.print("Success! Found {d} result(s).\n", .{response.total_results});

    if (response.results.len > 0) {
        try stdout.print("--------------------\n", .{});
        for (response.results, 0..) |result, i| {
            try stdout.print("Result {d}:\n", .{i + 1});

            try stdout.print("  Formatted: ", .{});
            try opencage.safeWriteUtf8(stdout, result.formatted);
            try stdout.print("\n", .{});

            try stdout.print("  Coords:    Lat={d:.7}, Lng={d:.7}\n", .{ result.geometry.lat, result.geometry.lng });
            try stdout.print("  Confidence: {d}/10\n", .{result.confidence});

            try stdout.print("  Country:   ", .{});
            try opencage.safeWriteUtf8Optional(stdout, result.components.country);
            try stdout.print("\n", .{});

            try stdout.print("  Timezone:  ", .{});
            if (result.annotations) |annotations| {
                if (annotations.timezone) |timezone| {
                    try opencage.safeWriteUtf8(stdout, timezone.name);
                } else {
                    try stdout.print("[No timezone data]", .{});
                }
            } else {
                try stdout.print("[No annotations data]", .{});
            }
            try stdout.print("\n", .{});

            try stdout.print("--------------------\n", .{});
        }
    } else {
        try stdout.print("Query was valid, but no results found.\n", .{});
    }

    if (response.rate) |rate| {
        try stdout.print("Rate Limit Info: Remaining={d}, Limit={d}, ResetsAt={d}\n", .{
            rate.remaining,
            rate.limit,
            rate.reset,
        });
    } else {
        try stdout.print("Rate Limit Info: Not provided (likely a subscription account).\n", .{});
    }
}
