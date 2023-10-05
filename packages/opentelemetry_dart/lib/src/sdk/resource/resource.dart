// Copyright 2021-2022 Workiva.
// Licensed under the Apache License, Version 2.0. Please see https://github.com/Workiva/opentelemetry-dart/blob/master/LICENSE for more information

import '../../../api.dart' as api;
import '../common/attributes.dart';

class Resource {
  final Attributes _attributes;
  final int? droppedAttributesCount;

  Resource(List<api.Attribute> attributes, [this.droppedAttributesCount])
      : _attributes = Attributes.empty() {
    for (final attribute in attributes) {
      if (attribute.value is! String) {
        throw ArgumentError('Attributes value must be String.');
      }
    }
    _attributes.addAll(attributes);
  }

  Resource.fromAttributes(this._attributes, [this.droppedAttributesCount]);

  Attributes get attributes => _attributes;
}
