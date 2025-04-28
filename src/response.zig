const std = @import("std");
const errors = @import("errors.zig");
const options = @import("options.zig");

const Allocator = std.mem.Allocator;
const json = std.json;
const ArrayList = std.ArrayList;

pub const LatLng = options.LatLng;
pub const Bounds = options.Bounds;

pub const License = struct {
    name: []const u8,
    url: []const u8,
};

pub const Rate = struct {
    limit: u64,
    remaining: u64,
    reset: u64,
};

pub const Status = struct {
    code: u16,
    message: []const u8,
};

pub const Timestamp = struct {
    created_http: []const u8,
    created_unix: u64,
};

pub const StayInformed = struct {
    blog: []const u8,
    mastodon: []const u8,
};

pub const DMS = struct {
    lat: []const u8,
    lng: []const u8,
};

pub const Mercator = struct {
    x: f64,
    y: f64,
};

pub const OSM = struct {
    edit_url: ?[]const u8 = null,
    note_url: ?[]const u8 = null,
    url: ?[]const u8 = null,
};

pub const UNM49 = struct {
    regions: std.json.Value,
    statistical_groupings: ?[][]const u8 = null,

    pub fn getRegionsMap(self: UNM49, allocator: Allocator) !std.StringHashMap([]const u8) {
        return try json.parse(std.StringHashMap([]const u8), self.regions, .{ .allocator = allocator });
    }
};

pub const Currency = struct {
    alternate_symbols: ?[][]const u8 = null,
    decimal_mark: []const u8,
    disambiguate_symbol: ?[]const u8 = null,
    format: ?[]const u8 = null,
    html_entity: []const u8,
    iso_code: []const u8,
    iso_numeric: []const u8,
    name: []const u8,
    smallest_denomination: u64,
    subunit: []const u8,
    subunit_to_unit: u64,
    symbol: []const u8,
    symbol_first: u8,
    thousands_separator: []const u8,
};

pub const TollDetails = struct {
    excluded: ?[][]const u8 = null,
    included: ?[][]const u8 = null,
    operator: ?[]const u8 = null,
};

pub const RoadInfo = struct {
    drive_on: []const u8,
    road: ?[]const u8 = null,
    road_type: ?[]const u8 = null,
    speed_in: []const u8,
    road_reference: ?[]const u8 = null,
    road_reference_intl: ?[]const u8 = null,

    lanes: ?u8 = null,
    maxheight: ?f32 = null,
    maxspeed: ?u32 = null,
    maxweight: ?f32 = null,
    maxwidth: ?f32 = null,
    oneway: ?[]const u8 = null,
    surface: ?[]const u8 = null,
    toll: ?[]const u8 = null,
    toll_details: ?TollDetails = null,
    width: ?f32 = null,
};

pub const RiseSet = struct {
    apparent: u64,
    astronomical: u64,
    civil: u64,
    nautical: u64,
};

pub const Sun = struct {
    rise: RiseSet,
    set: RiseSet,
};

pub const Timezone = struct {
    name: []const u8,
    now_in_dst: u8,
    offset_sec: i32,
    offset_string: []const u8,
    short_name: []const u8,
};

pub const What3Words = struct {
    words: []const u8,
};

pub const FIPS = struct {
    county: ?[]const u8 = null,
    state: ?[]const u8 = null,
};

pub const NUTSCode = struct {
    code: []const u8,
};

pub const NUTS = struct {
    NUTS0: ?NUTSCode = null,
    NUTS1: ?NUTSCode = null,
    NUTS2: ?NUTSCode = null,
    NUTS3: ?NUTSCode = null,
};

pub const Annotations = struct {
    DMS: ?DMS = null,
    MGRS: ?[]const u8 = null,
    Maidenhead: ?[]const u8 = null,
    Mercator: ?Mercator = null,
    OSM: ?OSM = null,
    UN_M49: ?UNM49 = null,
    callingcode: ?i32 = null,
    currency: ?Currency = null,
    flag: ?[]const u8 = null,
    geohash: ?[]const u8 = null,
    qibla: ?f64 = null,
    roadinfo: ?RoadInfo = null,
    sun: ?Sun = null,
    timezone: ?Timezone = null,
    what3words: ?What3Words = null,
    wikidata: ?[]const u8 = null,
    FIPS: ?FIPS = null,
    NUTS: ?NUTS = null,
};

pub const Components = struct {
    @"ISO_3166-1_alpha-2": ?[]const u8 = null,
    @"ISO_3166-1_alpha-3": ?[]const u8 = null,
    @"ISO_3166-2": ?[][]const u8 = null,
    _category: ?[]const u8 = null,
    _normalized_city: ?[]const u8 = null,
    _type: []const u8,
    continent: ?[]const u8 = null,
    country: ?[]const u8 = null,
    country_code: ?[]const u8 = null,
    state: ?[]const u8 = null,
    state_code: ?[]const u8 = null,
    state_district: ?[]const u8 = null,
    county: ?[]const u8 = null,
    city: ?[]const u8 = null,
    city_district: ?[]const u8 = null,
    town: ?[]const u8 = null,
    village: ?[]const u8 = null,
    municipality: ?[]const u8 = null,
    suburb: ?[]const u8 = null,
    neighbourhood: ?[]const u8 = null,
    postcode: ?[]const u8 = null,
    road: ?[]const u8 = null,
    road_type: ?[]const u8 = null,
    house_number: ?[]const u8 = null,
    building: ?[]const u8 = null,
    region: ?[]const u8 = null,
    archipelago: ?[]const u8 = null,
    island: ?[]const u8 = null,
    body_of_water: ?[]const u8 = null,
    place: ?[]const u8 = null,
    hamlet: ?[]const u8 = null,
    postal_city: ?[]const u8 = null,
    political_union: ?[]const u8 = null,
};

pub const Geometry = LatLng;

pub const DistanceFromQ = struct {
    meters: u64,
};

pub const Result = struct {
    annotations: ?Annotations = null,
    bounds: ?Bounds = null,
    components: Components,
    confidence: u8,
    formatted: []const u8,
    geometry: Geometry,
    distance_from_q: ?DistanceFromQ = null,
};

pub const ApiResponse = struct {
    documentation: ?[]const u8 = null,
    licenses: []License,
    rate: ?Rate = null,
    results: []Result,
    status: Status,
    stay_informed: ?StayInformed = null,
    thanks: ?[]const u8 = null,
    timestamp: ?Timestamp = null,
    total_results: usize,
    request: ?json.Value = null,
};

pub fn parseResponse(
    allocator: Allocator,
    json_payload: []const u8,
) errors.ErrorCode!std.json.Parsed(ApiResponse) {
    const parse_options = json.ParseOptions{
        .ignore_unknown_fields = true,
        .allocate = .alloc_always,
    };

    return json.parseFromSlice(ApiResponse, allocator, json_payload, parse_options) catch |err| {
        std.log.err("JSON parsing failed: {s}", .{ @errorName(err) });
        // Log small amount of payload for debugging
        const log_len = @min(json_payload.len, 256);
        std.log.debug("Failed JSON Payload (up to {d} bytes): {s}", .{ log_len, json_payload[0..log_len] });
        return errors.ErrorCode.JsonParseError;
    };
}

fn testAllocator() std.heap.GeneralPurposeAllocator(.{}) {
    return .{};
}

test "parse basic ApiResponse structure - empty results" {
    const sample_json =
        \\{
        \\  "documentation": "https://opencagedata.com/api",
        \\  "licenses": [{"name": "ODbL", "url": "url1"}],
        \\  "rate": {"limit": 2500, "remaining": 2499, "reset": 1678886400},
        \\  "results": [],
        \\  "status": {"code": 200, "message": "OK"},
        \\  "stay_informed": {"blog": "blog_url", "mastodon": "mastodon_url"},
        \\  "thanks": "Thanks!",
        \\  "timestamp": {"created_http": "now_http", "created_unix": 1678845000},
        \\  "total_results": 0
        \\}
    ;

    var gpa = testAllocator();
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var parsed_response = try parseResponse(allocator, sample_json);
    defer parsed_response.deinit();

    const response = parsed_response.value;

    try std.testing.expectEqualStrings("https://opencagedata.com/api", response.documentation.?);
    try std.testing.expectEqual(@as(usize, 1), response.licenses.len);
    try std.testing.expectEqualStrings("ODbL", response.licenses[0].name);
    try std.testing.expectEqualStrings("url1", response.licenses[0].url);
    try std.testing.expect(response.rate != null);
    try std.testing.expectEqual(@as(u64, 2500), response.rate.?.limit);
    try std.testing.expectEqual(@as(u64, 2499), response.rate.?.remaining);
    try std.testing.expectEqual(@as(u64, 1678886400), response.rate.?.reset);
    try std.testing.expectEqual(@as(usize, 0), response.results.len);
    try std.testing.expectEqual(@as(u16, 200), response.status.code);
    try std.testing.expectEqualStrings("OK", response.status.message);
    try std.testing.expectEqualStrings("blog_url", response.stay_informed.?.blog);
    try std.testing.expectEqualStrings("mastodon_url", response.stay_informed.?.mastodon);
    try std.testing.expectEqualStrings("Thanks!", response.thanks.?);
    try std.testing.expectEqualStrings("now_http", response.timestamp.?.created_http);
    try std.testing.expectEqual(@as(u64, 1678845000), response.timestamp.?.created_unix);
    try std.testing.expectEqual(@as(usize, 0), response.total_results);
    try std.testing.expect(response.request == null);
}

test "parse response with one result and basic fields" {
    const sample_json =
        \\{
        \\    "documentation": "https://opencagedata.com/api",
        \\    "licenses": [ { "name": "see attribution guide", "url": "https://opencagedata.com/credits" } ],
        \\    "rate": { "limit": 2500, "remaining": 2498, "reset": 1700000000 },
        \\    "results": [
        \\        {
        \\            "bounds": {
        \\                "northeast": { "lat": 52.5164327, "lng": 13.3777919 },
        \\                "southwest": { "lat": 52.5161167, "lng": 13.3771059 }
        \\            },
        \\            "components": {
        \\                "_category": "historic",
        \\                "_type": "building",
        \\                "building": "Brandenburg Gate",
        \\                "city": "Berlin",
        \\                "country": "Germany",
        \\                "country_code": "de",
        \\                "house_number": "1",
        \\                "political_union": "European Union",
        \\                "postcode": "10117",
        \\                "road": "Pariser Platz",
        \\                "state": "Berlin",
        \\                "suburb": "Mitte"
        \\            },
        \\            "confidence": 9,
        \\            "formatted": "Brandenburg Gate, Pariser Platz 1, 10117 Berlin, Germany",
        \\            "geometry": { "lat": 52.5162767, "lng": 13.3777025 }
        \\        }
        \\    ],
        \\    "status": { "code": 200, "message": "OK" },
        \\    "stay_informed": { "blog": "https://blog.opencagedata.com", "mastodon": "https://en.osm.town/@opencage" },
        \\    "thanks": "For using an OpenCage API",
        \\    "timestamp": { "created_http": "Wed, 15 Nov 2023 00:00:00 GMT", "created_unix": 1699999200 },
        \\    "total_results": 1
        \\}
    ;
    var gpa = testAllocator();
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var parsed_response = try parseResponse(allocator, sample_json);
    defer parsed_response.deinit();

    const response = parsed_response.value;

    try std.testing.expectEqual(@as(usize, 1), response.results.len);
    const result = response.results[0];

    try std.testing.expectEqualStrings("Brandenburg Gate, Pariser Platz 1, 10117 Berlin, Germany", result.formatted);
    try std.testing.expectEqual(@as(u8, 9), result.confidence);
    try std.testing.expectEqual(@as(f64, 52.5162767), result.geometry.lat);
    try std.testing.expectEqual(@as(f64, 13.3777025), result.geometry.lng);

    try std.testing.expect(result.bounds != null);
    try std.testing.expectEqual(52.5164327, result.bounds.?.northeast.lat);
    try std.testing.expectEqual(13.3777919, result.bounds.?.northeast.lng);
    try std.testing.expectEqual(52.5161167, result.bounds.?.southwest.lat);
    try std.testing.expectEqual(13.3771059, result.bounds.?.southwest.lng);

    try std.testing.expectEqualStrings("historic", result.components._category.?);
    try std.testing.expectEqualStrings("building", result.components._type);
    try std.testing.expectEqualStrings("Brandenburg Gate", result.components.building.?);
    try std.testing.expectEqualStrings("Berlin", result.components.city.?);
    try std.testing.expectEqualStrings("Germany", result.components.country.?);
    try std.testing.expectEqualStrings("de", result.components.country_code.?);
    try std.testing.expectEqualStrings("1", result.components.house_number.?);
    try std.testing.expectEqualStrings("European Union", result.components.political_union.?);
    try std.testing.expectEqualStrings("10117", result.components.postcode.?);
    try std.testing.expectEqualStrings("Pariser Platz", result.components.road.?);
    try std.testing.expectEqualStrings("Berlin", result.components.state.?);
    try std.testing.expectEqualStrings("Mitte", result.components.suburb.?);

    try std.testing.expect(result.annotations == null);
}

test "parse annotations including timezone and UNM49" {
    const sample_json =
        \\{
        \\  "documentation": "...",
        \\  "licenses": [],
        \\  "results": [
        \\    {
        \\      "annotations": {
        \\        "DMS": { "lat": "18° 0' 0.00'' N", "lng": "72° 0' 0.00'' W" },
        \\        "MGRS": "19QCJ8714087134",
        \\        "Maidenhead": "FK58",
        \\        "Mercator": { "x": -8015003.2, "y": 2048027.4 },
        \\        "OSM": { "url": "https://www.openstreetmap.org/?mlat=18.00000&mlon=-72.00000#map=5/18.00000/-72.00000" },
        \\        "UN_M49": {
        \\          "regions": { "AMERICAS": "019", "WORLD": "001", "HT": "332" },
        \\          "statistical_groupings": ["LDC", "SIDS"]
        \\        },
        \\        "callingcode": 1,
        \\        "currency": { "name": "United States Dollar", "iso_code": "USD", "symbol": "$", "decimal_mark": ".", "thousands_separator": ",", "subunit": "Cent", "subunit_to_unit": 100, "symbol_first": 1, "html_entity": "$", "iso_numeric": "840", "smallest_denomination": 1 },
        \\        "flag": "🇺🇸",
        \\        "geohash": "dek0k3v1g0h0k",
        \\        "qibla": 17.3,
        \\        "timezone": { "name": "America/New_York", "now_in_dst": 0, "offset_sec": -18000, "offset_string": "-0500", "short_name": "EST" },
        \\        "what3words": { "words": "filled.count.soap" },
        \\        "wikidata": "Q30"
        \\      },
        \\      "components": { "_type": "country", "country": "United States", "country_code": "us" },
        \\      "confidence": 1,
        \\      "formatted": "United States",
        \\      "geometry": { "lat": 38, "lng": -97 }
        \\    }
        \\  ],
        \\  "status": {"code": 200, "message": "OK"},
        \\  "stay_informed": {"blog": "", "mastodon": ""},
        \\  "thanks": "",
        \\  "timestamp": {"created_http": "", "created_unix": 0},
        \\  "total_results": 1
        \\}
    ;
    var gpa = testAllocator();
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var parsed_response = try parseResponse(allocator, sample_json);
    defer parsed_response.deinit();

    const response = parsed_response.value;

    try std.testing.expectEqual(@as(usize, 1), response.results.len);
    const result = response.results[0];
    const annotations = result.annotations orelse return error.TestUnexpectedNull;

    const timezone = annotations.timezone orelse return error.TestUnexpectedNull;
    try std.testing.expectEqualStrings("America/New_York", timezone.name);
    try std.testing.expectEqual(@as(u8, 0), timezone.now_in_dst);
    try std.testing.expectEqual(@as(i32, -18000), timezone.offset_sec);
    try std.testing.expectEqualStrings("-0500", timezone.offset_string);
    try std.testing.expectEqualStrings("EST", timezone.short_name);

    const unm49 = annotations.UN_M49 orelse return error.TestUnexpectedNull;
    var regions_map = try unm49.getRegionsMap(allocator);
    defer regions_map.deinit();

    try std.testing.expectEqual(@as(usize, 3), regions_map.count());
    try std.testing.expectEqualStrings("019", regions_map.get("AMERICAS") orelse return error.TestUnexpectedNull);
    try std.testing.expectEqualStrings("001", regions_map.get("WORLD") orelse return error.TestUnexpectedNull);
    try std.testing.expectEqualStrings("332", regions_map.get("HT") orelse return error.TestUnexpectedNull);

    const groupings = unm49.statistical_groupings orelse return error.TestUnexpectedNull;
    try std.testing.expectEqual(@as(usize, 2), groupings.len);
    try std.testing.expectEqualStrings("LDC", groupings[0]);
    try std.testing.expectEqualStrings("SIDS", groupings[1]);

    try std.testing.expectEqualStrings("🇺🇸", annotations.flag.?);
    try std.testing.expectEqualStrings("Q30", annotations.wikidata.?);
    try std.testing.expectEqual(1, annotations.callingcode.?);
    try std.testing.expectEqualStrings("filled.count.soap", annotations.what3words.?.words);
}

test "parse malformed JSON" {
    const malformed_json = "{ \"status\": { \"code\": 200, \"message\": \"OK }";

    var gpa = testAllocator();
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const result = parseResponse(allocator, malformed_json);
    try std.testing.expectError(errors.JsonParseError, result);
}

test "parse valid JSON with unknown fields" {
    const sample_json =
        \\{
        \\  "documentation": "https://opencagedata.com/api",
        \\  "licenses": [],
        \\  "rate": null,
        \\  "results": [],
        \\  "status": {"code": 200, "message": "OK"},
        \\  "stay_informed": {"blog": "blog_url", "mastodon": "mastodon_url"},
        \\  "thanks": "Thanks!",
        \\  "timestamp": {"created_http": "now_http", "created_unix": 1678845000},
        \\  "total_results": 0,
        \\  "some_new_future_field": "some_value",
        \\  "another_unknown_object": {"key": 123}
        \\}
    ;

    var gpa = testAllocator();
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var parsed_response = try parseResponse(allocator, sample_json);
    defer parsed_response.deinit();

    const response = parsed_response.value;

    try std.testing.expectEqualStrings("Thanks!", response.thanks.?);
    try std.testing.expectEqual(@as(u16, 200), response.status.code);
}
