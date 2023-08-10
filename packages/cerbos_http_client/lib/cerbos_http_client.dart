library cerbos_http_client;

import 'dart:io';

import 'package:cerbos_http_client/src/interceptor.dart';
import 'package:dio/dio.dart';

import 'src/externals.dart';

export 'src/externals.dart';

const _defaultUserAgent = 'cerbos-sdk-dart-http/0.0.2';

const _checkResources = '/check/resources';

class CerbosHttpClient {
  CerbosHttpClient(this.url) {
    _dio = Dio(
      BaseOptions(
        baseUrl: url,
        headers: {
          HttpHeaders.userAgentHeader: _defaultUserAgent,
        },
      ),
    )
      ..interceptors
          .add(CustomLogInterceptor(requestBody: true, responseBody: true))
      ..httpClientAdapter = HttpClientAdapter();
  }

  late final Dio _dio;

  final String url;

  Future<CheckResourcesResponse> checkResources(CheckResourcesRequest request) {
    return _dio.post(_checkResources, data: request.toMap()).then(
      (value) {
        return CheckResourcesResponse.fromMap(value.data);
      },
    );
  }

  Future<CheckResourceResponse> checkResource(CheckResourceRequest request) {
    return _dio.post(_checkResources, data: request.toMap()).then(
      (value) {
        return CheckResourceResponse.fromMap(value.data);
      },
    );
  }

  Future<bool> isAllowed(CheckResourceRequest request) {
    return checkResource(request).then((value) => value.result.isAllAllowed());
  }
}
