/// Base failure type returned to the presentation layer via `Either`.
/// Kept dependency-free (no equatable package required) to match the
/// blueprint's minimal dependency list.
abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class ConflictFailure extends Failure {
  final Map<String, dynamic> serverRecord;
  const ConflictFailure(super.message, this.serverRecord);
}

class ValidationFailure extends Failure {
  final Map<String, dynamic>? details;
  const ValidationFailure(super.message, {this.details});
}
