import 'package:json_annotation/json_annotation.dart';
import 'package:collection/collection.dart';

part 'scraper_model.g.dart';

// dart run build_runner build
enum RuleDataType {
  html,
  json,
}

enum SelectorType { element, text, html, attribute, json, value }

@JsonSerializable()
class SelectorRegex {
  final String from;
  final String? replace;
  final String? flags;

  bool get multiLine => flags?.toLowerCase().contains('m') ?? false;
  bool get caseSensitive => !(flags?.toLowerCase().contains('i') ?? false);
  bool get dotAll => flags?.toLowerCase().contains('g') ?? false;
  bool get unicode => flags?.toLowerCase().contains('u') ?? false;

  RegExp get pattern {
    return RegExp(from,
        multiLine: multiLine,
        caseSensitive: caseSensitive,
        unicode: unicode,
        dotAll: dotAll);
  }

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

  static List<SelectorRegex> _decodeRegexList(dynamic value) {
    if (value is String) return [SelectorRegex(value)];
    if (value is List) {
      return value.map((e) => _decodeRegex(e)).whereNotNull().toList();
    }
    return [];
  }

  static List<Selector>? _decodeChildren(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value
          .map((e) => Selector.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
  }

  final String id;
  final String? mapKey;
  String get key => mapKey ?? id;
  final SelectorType? type;

  SelectorType get autoType {
    if (type != null) return type!;
    if (value != null) return SelectorType.value;
    if (jsonAt != null) return SelectorType.json;
    if (attribute != null) return SelectorType.attribute;
    if (children != null) return SelectorType.element;
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
  final String? jsonAt;

  final dynamic value;

  Selector(
    this.id, {
    this.mapKey,
    this.type,
    this.jsonAt,
    this.parents,
    this.multiple = false,
    this.required = false,
    this.expressionContext,
    this.selector,
    this.attribute,
    this.regex,
    this.expression,
    this.children,
    this.value,
  });

  factory Selector.fromJson(Map<String, dynamic> json) =>
      _$SelectorFromJson(json);

  Map<String, dynamic> toJson() => _$SelectorToJson(this);

  @override
  String toString() {
    return "Selector<$id>";
  }
}

extension ListSelector on List<Selector> {
  List<Selector> getSubSelector(Selector selector) {
    final list = <Selector>[
      ...selector.children ?? [],
      ...where((element) => element.parents?.contains(selector.id) ?? false)
    ];
    return list;
  }
}

@JsonSerializable()
class Site {
  String host;
  bool authRequired;
  String? cookie;
  Site({required this.host, this.authRequired = false, this.cookie});

  factory Site.fromJson(Map<String, dynamic> json) => _$SiteFromJson(json);
  Map<String, dynamic> toJson() => _$SiteToJson(this);
}

@JsonSerializable()
class Rule {
  @JsonKey(fromJson: Selector._decodeRegexList)
  List<SelectorRegex> matches;

  RuleDataType type;
  String? selectorRoot;
  List<Selector>? selectors;
  Rule(
      {this.matches = const [],
      this.type = RuleDataType.html,
      this.selectorRoot,
      this.selectors});

  factory Rule.fromJson(Map<String, dynamic> json) => _$RuleFromJson(json);
  Map<String, dynamic> toJson() => _$RuleToJson(this);
}

@JsonSerializable()
class Scraper {
  String name;
  String description;
  String version;

  List<Rule> rules;
  List<Site> sites;

  Map<String, dynamic> constants;

  Scraper(
      {required this.name,
      this.description = '',
      this.version = '',
      this.rules = const [],
      this.sites = const [],
      this.constants = const {}});

  factory Scraper.fromJson(Map<String, dynamic> json) =>
      _$ScraperFromJson(json);
  Map<String, dynamic> toJson() => _$ScraperToJson(this);
}
