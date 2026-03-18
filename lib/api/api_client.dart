// This file is the main place that knows how to talk over HTTP
class ApiClient {
  final String baseUrl;

  ApiClient({required this.baseUrl});

  // Placeholder methods – implement with http/dio later
  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    // TODO: implement with real HTTP client
    throw UnimplementedError();
  }

  Future<dynamic> post(String path, {Object? body}) async {
    // TODO: implement with real HTTP client
    throw UnimplementedError();
  }
}