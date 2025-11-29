import '../errors/failures.dart';

/// A generic result type that can represent either success or failure
sealed class Result<T> {
  const Result();
  
  /// Creates a successful result
  const factory Result.success(T data) = Success<T>;
  
  /// Creates a failed result
  const factory Result.failure(Failure failure) = Failed<T>;
  
  /// Returns true if this result represents a success
  bool get isSuccess => this is Success<T>;
  
  /// Returns true if this result represents a failure
  bool get isFailure => this is Failed<T>;
  
  /// Returns the data if successful, null otherwise
  T? get data => switch (this) {
    Success<T>(data: final data) => data,
    Failed<T>() => null,
  };
  
  /// Returns the failure if failed, null otherwise
  Failure? get failure => switch (this) {
    Success<T>() => null,
    Failed<T>(failure: final failure) => failure,
  };
  
  /// Transforms the data if successful, otherwise returns the same failure
  Result<U> map<U>(U Function(T data) transform) {
    return switch (this) {
      Success<T>(data: final data) => Result.success(transform(data)),
      Failed<T>(failure: final failure) => Result.failure(failure),
    };
  }
  
  /// Transforms the data if successful, otherwise returns the same failure
  /// The transform function can return a Result, allowing for chaining
  Result<U> flatMap<U>(Result<U> Function(T data) transform) {
    return switch (this) {
      Success<T>(data: final data) => transform(data),
      Failed<T>(failure: final failure) => Result.failure(failure),
    };
  }
  
  /// Executes the appropriate callback based on the result
  R fold<R>(
    R Function(Failure failure) onFailure,
    R Function(T data) onSuccess,
  ) {
    return switch (this) {
      Success<T>(data: final data) => onSuccess(data),
      Failed<T>(failure: final failure) => onFailure(failure),
    };
  }
}

/// Represents a successful result
final class Success<T> extends Result<T> {
  @override
  final T data;
  
  const Success(this.data);
  
  @override
  String toString() => 'Success($data)';
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> &&
          runtimeType == other.runtimeType &&
          data == other.data;
  
  @override
  int get hashCode => data.hashCode;
  
  @override
  Failure? get failure => null;
}

/// Represents a failed result
final class Failed<T> extends Result<T> {
  @override
  final Failure failure;
  
  const Failed(this.failure);
  
  @override
  String toString() => 'Failed($failure)';
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failed<T> &&
          runtimeType == other.runtimeType &&
          failure == other.failure;
  
  @override
  int get hashCode => failure.hashCode;
  
  @override
  T? get data => null;
}