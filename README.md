# Zig OpenCage Geocoding Client

A Zig client library for the OpenCage Geocoding API. Provides forward and reverse geocoding capabilities with strong type safety and error handling.

**Official API Documentation**: https://opencagedata.com/api

## Features

- Forward geocoding (address to coordinates)
- Reverse geocoding (coordinates to address)
- Comprehensive error handling
- Support for all OpenCage API parameters

## Prerequisites

- Zig 0.14.0 or later
- libc (linked automatically)
- Platform dependencies:
  - macOS: Security framework
  - Windows: WinSock2 and crypto libraries

## Installation

Add to your `build.zig.zon`:
```zig
.{
    .dependencies = .{
        .opencage = .{
            .url = "https://github.com/geonot/zig-opencage/archive/refs/tags/v0.1.0.tar.gz",
        }
    }
}
```
And in `build.zig`:
```zig
const opencage = b.dependency("opencage", .{
    .target = target,
    .optimize = optimize,
});
exe.addModule("opencage", opencage.module("opencage"));
```
## Usage
```zig

const std = @import("std");
const opencage = @import("opencage");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const api_key = try std.process.getEnvVarOwned(allocator, "OPENCAGE_API_KEY");
    defer allocator.free(api_key);

    var client = try opencage.Client.init(allocator, api_key);
    defer client.deinit();

    // Forward geocoding
    const response = try client.geocodeForward(
        "Brandenburg Gate, Berlin",
        .{ .limit = 1, .language = "en" }
    );
    defer response.deinit();

    if (response.value.results.len > 0) {
        const result = response.value.results[0];
        std.debug.print("Lat: {d:.6}, Lng: {d:.6}\n", .{
            result.geometry.lat,
            result.geometry.lng
        });
    }
    
    // Reverse geocoding
    const reverse_response = try client.geocodeReverse(
        52.5162767, 
        13.3777025, 
        .{ .language = "en", .no_annotations = true }
    );
    defer reverse_response.deinit();
    
    if (reverse_response.value.results.len > 0) {
        const reverse_result = reverse_response.value.results[0];
        std.debug.print("Address: {s}\n", .{
            reverse_result.formatted
        });
    }
}
```
## API Key

    Get a free API key from https://opencagedata.com

    Set environment variable:

```bash

export OPENCAGE_API_KEY='your-api-key-here'
```

## Best Practices

Follow OpenCage's best practices and query formatting guidelines:

- [API Best Practices](https://opencagedata.com/api#bestpractices)
- [How to Format Your Geocoding Query](https://opencagedata.com/guides/how-to-format-your-geocoding-query)

## Running Examples
```bash
zig build run
```
## Testing

```bash
zig build test
```

## License

MIT License - See LICENSE for details.

## Contributing

    - Fork the repository
    - Create feature branch
    - Submit PR with tests
