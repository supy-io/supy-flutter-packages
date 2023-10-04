// Copyright 2021-2022 Workiva.
// Licensed under the Apache License, Version 2.0. Please see https://github.com/Workiva/opentelemetry-dart/blob/master/LICENSE for more information

import 'package:dio/dio.dart';
import 'package:mockito/mockito.dart';
import 'package:opentelemetry_dart/src/api/context/context.dart';
import 'package:opentelemetry_dart/src/api/exporters/span_exporter.dart';
import 'package:opentelemetry_dart/src/api/span_processors/span_processor.dart';
import 'package:opentelemetry_dart/src/api/trace/span.dart';

class MockContext extends Mock implements Context {}

class MockHTTPClient extends Mock implements Dio {}

class MockSpan extends Mock implements Span {}

class MockSpanExporter extends Mock implements SpanExporter {}

class MockSpanProcessor extends Mock implements SpanProcessor {}
