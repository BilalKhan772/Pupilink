
class CallableFunctionResult<T> {
  const CallableFunctionResult({
    required this.data,
    this.message,
  });

  final T data;
  final String? message;

  factory CallableFunctionResult.fromData(
    T data, {
    String? message,
  }) {
    return CallableFunctionResult<T>(
      data: data,
      message: message,
    );
  }
}
