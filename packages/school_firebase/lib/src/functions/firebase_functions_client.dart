
import 'package:cloud_functions/cloud_functions.dart';

import 'callable_function_result.dart';
import 'functions_error_mapper.dart';

class FirebaseFunctionsClient {
  FirebaseFunctionsClient({
    FirebaseFunctions? functions,
    FunctionsErrorMapper errorMapper = const FunctionsErrorMapper(),
  })  : _functions = functions ?? FirebaseFunctions.instance,
        _errorMapper = errorMapper;

  final FirebaseFunctions _functions;
  final FunctionsErrorMapper _errorMapper;

  Future<CallableFunctionResult<dynamic>> call(
    String functionName, {
    Map<String, dynamic> data = const {},
    Duration? timeout,
  }) async {
    final name = functionName.trim();

    if (name.isEmpty) {
      throw ArgumentError.value(
        functionName,
        'functionName',
        'Function name cannot be empty.',
      );
    }

    try {
      final callable = _functions.httpsCallable(
        name,
        options: timeout == null
            ? null
            : HttpsCallableOptions(timeout: timeout),
      );

      final result = await callable.call<dynamic>(data);

      return CallableFunctionResult<dynamic>(
        data: result.data,
      );
    } on FirebaseFunctionsException {
      rethrow;
    }
  }

  String getErrorMessage(Object error) {
    return _errorMapper.toMessage(error);
  }
}
