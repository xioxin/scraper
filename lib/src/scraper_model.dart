import 'package:json_annotation/json_annotation.dart';
part 'scraper_model.g.dart';

enum SelectorType {
  element,
  text,
  attribute,
}
enum SelectorDataType {
  string,
  bool,
  int,
  decimal,
}

@JsonSerializable()
class SelectorRegex {
  final String from;
  final String? replace;
  final String? flags;

  SelectorRegex(this.from, {this.replace, this.flags});

  factory SelectorRegex.fromJson(Map<String, dynamic> json) =>
      _$SelectorRegexFromJson(json);

  Map<String, dynamic> toJson() => _$SelectorRegexToJson(this);
}

@JsonSerializable()
class Selector {
  static List<String>? _decodeParentsList(dynamic value) {
    if (value == null) return null;
    if (value is List) return value.whereType<String>().toList();
    if (value is String) {
      return value
          .split(',')
          .map((e) => e.trim())
          .where((element) => element != '')
          .whereType<String>()
          .toList();
    }
    return [];
  }

  static SelectorRegex? _decodeRegex(dynamic value) {
    if (value == null) return null;
    if (value is String) return SelectorRegex(value);
    return SelectorRegex.fromJson(Map<String, dynamic>.from(value));
  }

  static List<Selector>? _decodeChildren(dynamic value) {

    if (value == null) return null;
    if (value is List){
      return value
          .map((e) => Selector.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
  }

  final String id;
  final SelectorType? type;

  SelectorType get autoType {
    if(type != null) return type!;
    if(attribute != null) return SelectorType.attribute;
    return SelectorType.text;
  }

  final bool required;
  final bool multiple;

  @JsonKey(fromJson: _decodeParentsList)
  final List<String>? parents;

  @JsonKey(fromJson: _decodeChildren)
  final List<Selector>? children;

  final String? selector;
  final String? attribute;

  @JsonKey(fromJson: _decodeRegex)
  final SelectorRegex? regex;
  final String? expression;
  final Map<String, dynamic>? expressionContext;
  final SelectorDataType? valueType;

  Selector(
    this.id, {
    this.type,
    this.parents,
    this.multiple = false,
    this.required = false,
    this.valueType,
    this.expressionContext,
    this.selector,
    this.attribute,
    this.regex,
    this.expression,
    this.children,
  });

  factory Selector.fromJson(Map<String, dynamic> json) =>
      _$SelectorFromJson(json);

  Map<String, dynamic> toJson() => _$SelectorToJson(this);
}
