/// Thrown when a remote API call fails (non-2xx response, timeout, etc).
class ServerException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;

  ServerException(this.message, {this.statusCode, this.errorCode});

  @override
  String toString() => 'ServerException($statusCode - $errorCode): $message';
}

/// Thrown when a local SQLite operation fails.
class CacheException implements Exception {
  final String message;

  CacheException(this.message);

  @override
  String toString() => 'CacheException: $message';
}

/// Thrown when the device has no network connectivity and a request
/// cannot be optimistically queued.
class NetworkException implements Exception {
  final String message;

  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

/// Thrown when a server rejects a mutation due to a stale `version`
/// (optimistic concurrency conflict). Carries the authoritative record
/// returned by the server so the caller can reconcile local state.
class ConflictException implements Exception {
  final String message;
  final Map<String, dynamic> serverRecord;

  ConflictException(this.message, this.serverRecord);

  @override
  String toString() => 'ConflictException: $message';
}
