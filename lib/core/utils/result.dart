import '../errors/failures.dart';

/// 成功または失敗を表すジェネリックな結果型
sealed class Result<T> {
  const Result();

  /// 成功した結果を生成する
  const factory Result.success(T data) = Success<T>;

  /// 失敗した結果を生成する
  const factory Result.failure(Failure failure) = Failed<T>;

  /// この結果が成功を表す場合にtrueを返す
  bool get isSuccess => this is Success<T>;

  /// この結果が失敗を表す場合にtrueを返す
  bool get isFailure => this is Failed<T>;

  /// 成功の場合はデータを返し、そうでなければnullを返す
  T? get data => switch (this) {
    Success<T>(data: final data) => data,
    Failed<T>() => null,
  };

  /// 失敗の場合はFailureを返し、そうでなければnullを返す
  Failure? get failure => switch (this) {
    Success<T>() => null,
    Failed<T>(failure: final failure) => failure,
  };

  /// 成功の場合はデータを変換し、そうでなければ同じ失敗を返す
  Result<U> map<U>(U Function(T data) transform) {
    return switch (this) {
      Success<T>(data: final data) => Result.success(transform(data)),
      Failed<T>(failure: final failure) => Result.failure(failure),
    };
  }

  /// 成功の場合はデータを変換し、そうでなければ同じ失敗を返す
  /// 変換関数はResultを返すことができ、チェーンが可能
  Result<U> flatMap<U>(Result<U> Function(T data) transform) {
    return switch (this) {
      Success<T>(data: final data) => transform(data),
      Failed<T>(failure: final failure) => Result.failure(failure),
    };
  }

  /// 結果に基づいて適切なコールバックを実行する
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

/// 成功した結果を表す
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

/// 失敗した結果を表す
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