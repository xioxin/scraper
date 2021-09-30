// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scraper_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SelectorRegex _$SelectorRegexFromJson(Map<String, dynamic> json) =>
    SelectorRegex(
      json['from'] as String,
      replace: json['replace'] as String?,
      flags: json['flags'] as String?,
    );

Map<String, dynamic> _$SelectorRegexToJson(SelectorRegex instance) =>
    <String, dynamic>{
      'from': instance.from,
      'replace': instance.replace,
      'flags': instance.flags,
    };

Selector _$SelectorFromJson(Map<String, dynamic> json) => Selector(
      json['id'] as String,
      type: _$enumDecodeNullable(_$SelectorTypeEnumMap, json['type']),
      parents: Selector._decodeParentsList(json['parents']),
      multiple: json['multiple'] as bool? ?? false,
      required: json['required'] as bool? ?? false,
      valueType:
          _$enumDecodeNullable(_$SelectorDataTypeEnumMap, json['valueType']),
      expressionContext: json['expressionContext'] as Map<String, dynamic>?,
      selector: json['selector'] as String?,
      attribute: json['attribute'] as String?,
      regex: Selector._decodeRegex(json['regex']),
      expression: json['expression'] as String?,
      children: Selector._decodeChildren(json['children']),
    );

Map<String, dynamic> _$SelectorToJson(Selector instance) => <String, dynamic>{
      'id': instance.id,
      'type': _$SelectorTypeEnumMap[instance.type],
      'required': instance.required,
      'multiple': instance.multiple,
      'parents': instance.parents,
      'children': instance.children,
      'selector': instance.selector,
      'attribute': instance.attribute,
      'regex': instance.regex,
      'expression': instance.expression,
      'expressionContext': instance.expressionContext,
      'valueType': _$SelectorDataTypeEnumMap[instance.valueType],
    };

K _$enumDecode<K, V>(
  Map<K, V> enumValues,
  Object? source, {
  K? unknownValue,
}) {
  if (source == null) {
    throw ArgumentError(
      'A value must be provided. Supported values: '
      '${enumValues.values.join(', ')}',
    );
  }

  return enumValues.entries.singleWhere(
    (e) => e.value == source,
    orElse: () {
      if (unknownValue == null) {
        throw ArgumentError(
          '`$source` is not one of the supported values: '
          '${enumValues.values.join(', ')}',
        );
      }
      return MapEntry(unknownValue, enumValues.values.first);
    },
  ).key;
}

K? _$enumDecodeNullable<K, V>(
  Map<K, V> enumValues,
  dynamic source, {
  K? unknownValue,
}) {
  if (source == null) {
    return null;
  }
  return _$enumDecode<K, V>(enumValues, source, unknownValue: unknownValue);
}

const _$SelectorTypeEnumMap = {
  SelectorType.element: 'element',
  SelectorType.text: 'text',
  SelectorType.attribute: 'attribute',
};

const _$SelectorDataTypeEnumMap = {
  SelectorDataType.string: 'string',
  SelectorDataType.bool: 'bool',
  SelectorDataType.int: 'int',
  SelectorDataType.decimal: 'decimal',
};
