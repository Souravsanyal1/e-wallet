/// Result type (Ok / Err pattern) as specified in architecture.md and testing.md
sealed class Result<T> {
  const Result();

  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  T? get valueOrNull => switch (this) {
        Ok(value: final v) => v,
        Err() => null,
      };

  AppException? get errorOrNull => switch (this) {
        Ok() => null,
        Err(error: final e) => e,
      };

  R when<R>({
    required R Function(T value) ok,
    required R Function(AppException error) err,
  }) =>
      switch (this) {
        Ok(value: final v) => ok(v),
        Err(error: final e) => err(e),
      };
}

final class Ok<T> extends Result<T> {
  final T value;
  const Ok(this.value);

  @override
  String toString() => 'Ok($value)';
}

final class Err<T> extends Result<T> {
  final AppException error;
  const Err(this.error);

  @override
  String toString() => 'Err($error)';
}

class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const AppException(this.message, {this.code, this.details});

  factory AppException.network([String message = 'Network connection error']) =>
      AppException(message, code: 'NETWORK_ERROR');

  factory AppException.unauthorized([String message = 'Unauthorized action']) =>
      AppException(message, code: 'UNAUTHORIZED');

  factory AppException.notFound([String message = 'Resource not found']) =>
      AppException(message, code: 'NOT_FOUND');

  factory AppException.validation([String message = 'Invalid input data']) =>
      AppException(message, code: 'VALIDATION_ERROR');

  factory AppException.walletRejected([String message = 'User rejected wallet request']) =>
      AppException(message, code: 'WALLET_REJECTED');

  factory AppException.server([String message = 'Server error occurred']) =>
      AppException(message, code: 'SERVER_ERROR');

  @override
  String toString() => 'AppException: $message ($code)';
}
