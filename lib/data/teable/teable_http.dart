import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;

/// Request-level failures.
sealed class TeableRequestFailure {
  final String message;
  const TeableRequestFailure(this.message);
}

class NetworkFailure extends TeableRequestFailure {
  const NetworkFailure(super.message);
}

class UnauthorizedFailure extends TeableRequestFailure {
  const UnauthorizedFailure(super.message);
}

class HttpFailure extends TeableRequestFailure {
  final int statusCode;
  const HttpFailure(this.statusCode, super.message);
}

class MalformedResponseFailure extends TeableRequestFailure {
  const MalformedResponseFailure(super.message);
}

/// The HTTP seam. `data/` only: nothing above this layer
/// may import package:http or any browser-only API.
abstract interface class TeableHttpClient {
  Future<Either<TeableRequestFailure, dynamic>> get(
    String path, {
    Map<String, String>? query,
  });
}

/// Real implementation. Talks to the self-hosted Teable instance.
class HttpTeableClient implements TeableHttpClient {
  final Uri baseUri;
  final String pat;
  final http.Client _client;

  HttpTeableClient({
    required String baseUrl,
    required this.pat,
    http.Client? client,
  }) : baseUri = Uri.parse(baseUrl),
       _client = client ?? http.Client();

  @override
  Future<Either<TeableRequestFailure, dynamic>> get(
    String path, {
    Map<String, String>? query,
  }) async {
    final uri = baseUri.replace(path: path, queryParameters: query);
    final http.Response response;
    try {
      response = await _client.get(
        uri,
        headers: {'Authorization': 'Bearer $pat'},
      );
    } on Exception catch (e) {
      return Left(NetworkFailure('GET $uri failed: $e'));
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      return Left(
        UnauthorizedFailure('GET $uri returned ${response.statusCode}'),
      );
    }
    if (response.statusCode != 200) {
      return Left(
        HttpFailure(
          response.statusCode,
          'GET $uri returned ${response.statusCode}',
        ),
      );
    }

    try {
      return Right(jsonDecode(response.body));
    } on FormatException catch (e) {
      return Left(
        MalformedResponseFailure('GET $uri body is not JSON: ${e.message}'),
      );
    }
  }
}
