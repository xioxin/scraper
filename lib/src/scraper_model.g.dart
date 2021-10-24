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
      mapKey: json['mapKey'] as String?,
      type: _$enumDecodeNullable(_$SelectorTypeEnumMap, json['type']),
      jsonAt: json['jsonAt'] as String?,
      parents: Selector._decodeParentsList(json['parents']),
      multiple: json['multiple'] as bool? ?? false,
      required: json['required'] as bool? ?? false,
      expressionContext: json['expressionContext'] as Map<String, dynamic>?,
      selector: json['selector'] as String?,
      attribute: json['attribute'] as String?,
      regex: Selector._decodeRegex(json['regex']),
      expression: json['expression'] as String?,
      children: Selector._decodeChildren(json['children']),
    );

Map<String, dynamic> _$SelectorToJson(Selector instance) => <String, dynamic>{
      'id': instance.id,
      'mapKey': instance.mapKey,
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
      'jsonAt': instance.jsonAt,
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
  SelectorType.html: 'html',
  SelectorType.attribute: 'attribute',
  SelectorType.json: 'json',
};

Site _$SiteFromJson(Map<String, dynamic> json) => Site(
      host: json['host'] as String,
      authRequired: json['authRequired'] as bool? ?? false,
      cookie: json['cookie'] as String?,
    );

Map<String, dynamic> _$SiteToJson(Site instance) => <String, dynamic>{
      'host': instance.host,
      'authRequired': instance.authRequired,
      'cookie': instance.cookie,
    };

Rule _$RuleFromJson(Map<String, dynamic> json) => Rule(
      matches: json['matches'] == null
          ? const []
          : Selector._decodeRegexList(json['matches']),
      type: _$enumDecodeNullable(_$RuleDataTypeEnumMap, json['type']) ??
          RuleDataType.html,
      selectorRoot: json['selectorRoot'] as String?,
      selectors: (json['selectors'] as List<dynamic>?)
          ?.map((e) => Selector.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$RuleToJson(Rule instance) => <String, dynamic>{
      'matches': instance.matches,
      'type': _$RuleDataTypeEnumMap[instance.type],
      'selectorRoot': instance.selectorRoot,
      'selectors': instance.selectors,
    };

const _$RuleDataTypeEnumMap = {
  RuleDataType.html: 'html',
  RuleDataType.json: 'json',
};

Scraper _$ScraperFromJson(Map<String, dynamic> json) => Scraper(
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      version: json['version'] as String? ?? '',
      rules: (json['rules'] as List<dynamic>?)
              ?.map((e) => Rule.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      sites: (json['sites'] as List<dynamic>?)
              ?.map((e) => Site.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      constants: json['constants'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$ScraperToJson(Scraper instance) => <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'version': instance.version,
      'rules': instance.rules,
      'sites': instance.sites,
      'constants': instance.constants,
    };
