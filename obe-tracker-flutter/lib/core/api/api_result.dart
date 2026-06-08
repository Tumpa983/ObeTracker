class ApiResult<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  const ApiResult.success(this.data)
      : error = null,
        isSuccess = true;

  const ApiResult.failure(this.error)
      : data = null,
        isSuccess = false;

  R when<R>({
    required R Function(T data) success,
    required R Function(String error) failure,
  }) {
    if (isSuccess && data != null) return success(data as T);
    return failure(error ?? 'Unknown error');
  }
}

String parseApiError(dynamic e) {
  try {
    // Dio error with response body
    final response = (e as dynamic).response;
    if (response != null) {
      final data = response.data;
      if (data is Map) {
        if (data['error'] != null) return data['error'].toString();
        if (data['message'] != null) return data['message'].toString();
      }
      if (data is String && data.isNotEmpty) return data;
    }
    // Dio error message
    final msg = (e as dynamic).message;
    if (msg != null && msg.toString().isNotEmpty) return msg.toString();
  } catch (_) {}
  final str = e.toString();
  // Strip common prefixes
  for (final prefix in ['Exception: ', 'DioException: ', 'DioError: ']) {
    if (str.startsWith(prefix)) return str.substring(prefix.length);
  }
  return str.isNotEmpty ? str : 'An unexpected error occurred';
}
