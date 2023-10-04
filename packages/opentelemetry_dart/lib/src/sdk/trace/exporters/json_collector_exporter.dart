// Copyright 2021-2022 Workiva.
// Licensed under the Apache License, Version 2.0. Please see https://github.com/Workiva/opentelemetry-dart/blob/master/LICENSE for more information

import 'package:dio/dio.dart';

import '../../../../api.dart' as api;
import '../../../../sdk.dart' as sdk;

class JsonCollectorExporter implements api.SpanExporter {
  String uri;
  late Dio client;
  var _isShutdown = false;

  JsonCollectorExporter(this.uri, {Dio? dio}) {
    client = dio ?? Dio();
    client.options
      ..baseUrl = uri
      ..headers.addAll({'Content-Type': 'application/json; charset=UTF-8'});
  }

  @override
  void export(List<api.Span> spans) {
    if (_isShutdown) {
      return;
    }

    if (spans.isEmpty) {
      return;
    }

    final spansToProtobuf = _spansResourceSpans(spans);

    final data = _resourceSpansToMap(spansToProtobuf);
    client.post(
      uri,
      data: data,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Origin': 'https://mobile.supy.io',
        },
      ),
    );
  }

  Map<String, dynamic> _resourceSpansToMap(
      Iterable<sdk.ResourceSpans> resourceSpans) {
    return {
      'resourceSpans': resourceSpans.map(_resourceSpanToMap).toList(),
    };
  }

  Map<String, dynamic> _resourceSpanToMap(sdk.ResourceSpans resourceSpan) {
    final map = <String, dynamic>{};
    final instrumentationLibrarySpans = [];

    final resourceAttributes =
        _attributesToList(resourceSpan.resource.attributes);
    final droppedAttributesCount = resourceSpan.resource.droppedAttributesCount;

    for (final instrumentationLibrarySpan
        in resourceSpan.instrumentationLibrarySpans) {
      final spans = instrumentationLibrarySpan.spans;
      final instrumentationLibrary =
          instrumentationLibrarySpan.instrumentationLibrary;

      instrumentationLibrarySpans.add(
        {
          'spans': _spansToList(spans),
          'scope': {
            'name': instrumentationLibrary.name,
            'version': instrumentationLibrary.version,
          }
        },
      );
    }

    map['resource'] = {
      'attributes': resourceAttributes,
      'droppedAttributesCount': droppedAttributesCount ?? 0
    };

    map['scopeSpans'] = instrumentationLibrarySpans;

    return map;
  }

  List<Map<String, dynamic>> _spansToList(List<sdk.Span> spans) {
    return spans.map((span) {
      final attributes = span.attributes;
      return {
        'spanId': span.spanContext?.spanId.toString(),
        'traceId': span.spanContext?.traceId.toString(),
        'name': span.name,
        'kind': span.kind.index,
        'status': {
          'code': span.status.code.index,
          'message': span.status.description,
        },
        'startTimeUnixNano': span.startTime.toInt(),
        'endTimeUnixNano': span.endTime?.toInt(),
        'droppedAttributesCount': span.droppedAttributes,
        'droppedEventsCount': 0,
        'attributes': _attributesToList(attributes),
        'events': [],
      };
    }).toList();
  }

  List<Map<String, dynamic>> _attributesToList(sdk.Attributes attributes) {
    return attributes.keys
        .map(
          (key) => {
            'key': key,
            'value': _attribute(attributes.get(key)),
          },
        )
        .toList();
  }

  /// Group and construct the protobuf equivalent of the given list of [api.Span]s.
  /// Spans are grouped by a trace provider's [sdk.Resource] and a tracer's
  /// [api.InstrumentationLibrary].
  Iterable<sdk.ResourceSpans> _spansResourceSpans(List<api.Span> spans) {
    // use a map of maps to group spans by resource and instrumentation library
    final rsm =
        <sdk.Resource?, Map<api.InstrumentationLibrary?, List<sdk.Span>>>{};
    for (final span in spans) {
      final il = rsm[(span as sdk.Span).resource] ??
          <api.InstrumentationLibrary, List<sdk.Span>>{};
      il[span.instrumentationLibrary] =
          il[span.instrumentationLibrary] ?? <sdk.Span>[]
            ..add(span);
      rsm[span.resource] = il;
    }

    final rss = <sdk.ResourceSpans>[];
    for (final il in rsm.entries) {
      // for each distinct resource, construct the protobuf equivalent
      final attributes = il.key!.attributes;

      final rs = sdk.ResourceSpans(
        resource: sdk.Resource.fromAttributes(attributes),
        instrumentationLibrarySpans: [],
      );
      // for each distinct instrumentation library, construct the protobuf equivalent
      for (final ils in il.value.entries) {
        rs.instrumentationLibrarySpans.add(
          sdk.InstrumentationLibrarySpans(
            spans: ils.value,
            instrumentationLibrary:
                sdk.InstrumentationLibrary(ils.key!.name, ils.key!.version!),
          ),
        );
      }
      rss.add(rs);
    }
    return rss;
  }

  Map<String, dynamic> _attribute(Object? object) {
    switch (object.runtimeType) {
      case int:
        return {'intValue': object};
      case String:
        return {'stringValue': object};
      case bool:
        return {'boolValue': object};
      case double:
        return {'doubleValue': object};
      case List:
        return {
          'arrayValue': (object as List<Object>).map(_attribute).toList(),
        };
    }

    return {};
  }

  @override
  void forceFlush() {
    return;
  }

  @override
  void shutdown() {
    _isShutdown = true;
    client.close();
  }
}
