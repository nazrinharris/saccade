import 'package:equatable/equatable.dart';

/// A failure Saccade can act on. Carries the originating stack trace
/// so a failure is never just a message.
sealed class Failure extends Equatable {
  final String message;
  final StackTrace stackTrace;

  const Failure(this.message, {required this.stackTrace});

  @override
  List<Object?> get props => [message, stackTrace];
}

/// No usable connection to the backend.
class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {required super.stackTrace});
}

/// The credential was rejected (401/403).
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure(super.message, {required super.stackTrace});
}

/// The backend answered with an unexpected status.
class HttpFailure extends Failure {
  final int statusCode;

  const HttpFailure(
    super.message, {
    required this.statusCode,
    required super.stackTrace,
  });

  @override
  List<Object?> get props => [message, stackTrace, statusCode];
}

/// The response arrived but did not have the expected shape.
class MalformedResponseFailure extends Failure {
  const MalformedResponseFailure(super.message, {required super.stackTrace});
}

/// A schema problem: an unknown kind, an unrecognized enum value.
/// These are programming errors, kept typed so they can surface visibly.
class SchemaFailure extends Failure {
  const SchemaFailure(super.message, {required super.stackTrace});
}
