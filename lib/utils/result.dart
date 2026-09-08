/// Result type for handling success and failure cases
/// Provides a more type-safe alternative to try-catch blocks

/// Represents either a successful result [T] or an error [E]
abstract class Result<T, E> {
  /// Execute different functions based on the result type
  R when<R>({
    required R Function(T value) onSuccess,
    required R Function(E error) onError,
  });

  /// Map the success value if present
  Result<U, E> map<U>(U Function(T value) transform);

  /// Map the error if present
  Result<T, F> mapError<F>(F Function(E error) transform);

  /// Flatten nested results
  Result<T, E> flatten() {
    return when(
      onSuccess: (value) => value is Result<T, E> ? value : Success(value as T),
      onError: (error) => Failure(error),
    );
  }

  /// Get the value or null
  T? getOrNull() {
    return when(
      onSuccess: (value) => value,
      onError: (_) => null,
    );
  }

  /// Get the error or null
  E? getErrorOrNull() {
    return when(
      onSuccess: (_) => null,
      onError: (error) => error,
    );
  }

  /// Check if result is success
  bool get isSuccess => this is Success<T, E>;

  /// Check if result is failure
  bool get isFailure => this is Failure<T, E>;
}

/// Success result containing a value
class Success<T, E> extends Result<T, E> {
  final T value;

  Success(this.value);

  @override
  R when<R>({
    required R Function(T value) onSuccess,
    required R Function(E error) onError,
  }) {
    return onSuccess(value);
  }

  @override
  Result<U, E> map<U>(U Function(T value) transform) {
    return Success(transform(value));
  }

  @override
  Result<T, F> mapError<F>(F Function(E error) transform) {
    return Success(value) as Result<T, F>;
  }

  @override
  String toString() => 'Success($value)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Success<T, E> && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}

/// Failure result containing an error
class Failure<T, E> extends Result<T, E> {
  final E error;

  Failure(this.error);

  @override
  R when<R>({
    required R Function(T value) onSuccess,
    required R Function(E error) onError,
  }) {
    return onError(error);
  }

  @override
  Result<U, E> map<U>(U Function(T value) transform) {
    return Failure(error) as Result<U, E>;
  }

  @override
  Result<T, F> mapError<F>(F Function(E error) transform) {
    return Failure(transform(error));
  }

  @override
  String toString() => 'Failure($error)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Failure<T, E> && other.error == error;
  }

  @override
  int get hashCode => error.hashCode;
}

/// Extension methods for Result type
extension ResultExtension<T, E> on Result<T, E> {
  /// Convert to Future
  Future<Result<T, E>> toFuture() async => this;

  /// Combine with another result using applicative pattern
  Result<U, E> applyWith<U>(Result<U Function(T), E> resultFn) {
    return when(
      onSuccess: (value) => resultFn.map((fn) => fn(value)),
      onError: (error) => Failure(error),
    );
  }

  /// Chain results together (monadic bind)
  Result<U, E> flatMap<U>(Result<U, E> Function(T value) transform) {
    return when(
      onSuccess: (value) => transform(value),
      onError: (error) => Failure(error),
    );
  }
}

/// Extension for wrapping functions that might throw
extension TryCatchExtension<T> on Future<T> {
  /// Wrap a future that might throw into a Result
  Future<Result<T, Exception>> toResult() async {
    try {
      final value = await this;
      return Success(value);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }
}
