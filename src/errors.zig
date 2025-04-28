const std = @import("std");

pub const ErrorCode = error{
    NetworkError,
    HttpError,
    JsonParseError,
    ApiResponseError,
    BadRequest,
    InvalidApiKey,
    QuotaExceeded,
    Forbidden,
    RequestTooLong,
    RateLimited,
    ServerError,
    InvalidUrl,
    AllocationFailed,
    MissingDependency,
    BufferTooSmall,
};
