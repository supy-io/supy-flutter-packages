// Copyright 2021-2022 Workiva.
// Licensed under the Apache License, Version 2.0. Please see https://github.com/Workiva/opentelemetry-dart/blob/master/LICENSE for more information

@TestOn('chrome')
import 'package:opentelemetry_dart/api.dart' as api;
import 'package:opentelemetry_dart/sdk.dart' as sdk;
import 'package:opentelemetry_dart/src/sdk/platforms/web/time_providers/web_time_provider.dart';
import 'package:opentelemetry_dart/src/sdk/trace/span.dart';
import 'package:test/test.dart';

void main() {
  test('records start and end times with browser performance API', () async {
    final span = Span(
        'testStartAndEndTimes',
        sdk.SpanContext(api.TraceId([1, 2, 3]), api.SpanId([7, 8, 9]),
            api.TraceFlags.none, sdk.TraceState.empty()),
        api.SpanId([4, 5, 6]),
        [],
        TimeProvider(),
        sdk.Resource([]),
        sdk.InstrumentationLibrary('library_name', 'library_version'))
      ..end();

    expect(span.startTime, lessThanOrEqualTo(span.endTime!));
  });
}
