class Result<T> {
  final T? data;
  final String? error;

  const Result._({
    this.data,
    this.error,
  });

  const Result.success(T data)
      : this._(data: data);

  const Result.failure(String error)
      : this._(error: error);

  bool get isSuccess => error == null;

  bool get isFailure => error != null;

  T get value {
    if (data == null) {
      throw StateError(
        'Result does not contain successful data.',
      );
    }

    return data as T;
  }

  String get errorMessage {
    if (error == null) {
      throw StateError(
        'Result does not contain an error.',
      );
    }

    return error!;
  }
}