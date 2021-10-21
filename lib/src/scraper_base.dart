import 'dart:convert';
import 'dart:io';

import 'package:expressions/expressions.dart';
import 'package:universal_html/controller.dart';
import 'package:universal_html/html.dart';
import 'package:yaml/yaml.dart';
import 'scraper_model.dart';
import 'package:collection/collection.dart';

typedef ScraperRequestFunc = Future<String> Function(
    ScraperController controller, Scraper scraper, Uri uri);

class ScraperParser {
  final WindowController windowController = WindowController();
  final ScraperController scraperController;
  final Scraper scraper;
  final Rule rule;
  final String data;
  Object? json;
  final Map<String, dynamic> variable;
  List<Selector> selectorList = [];

  ScraperParser(this.scraperController, this.scraper, this.rule, this.data,
      {this.variable = const {}}) {
    selectorList = rule.selectors ?? scraper.selectors;
    if (rule.type == RuleDataType.html) {
      windowController.openContent(data);
    } else if (rule.type == RuleDataType.json) {
      json = jsonDecode(data);
    }
  }

  Map<String, dynamic>? parse() {
    final rootId = rule.selectorRoot;
    if (rule.type == RuleDataType.html) {
      assert(windowController.window?.document.documentElement != null);
      final rootSelector = selectorList
          .where((e) => e.parents?.contains(rootId) ?? rootId == null)
          .toList();
      return parseElementMap(
          windowController.window!.document.documentElement!, rootSelector);
    } else if (rule.type == RuleDataType.json) {
      return parseJson(rootId: rootId);
    }
  }

  Map<String, dynamic> parseJson(
      {Object? inputData, List<Selector>? selectorList, String? rootId}) {
    Map<String, dynamic> data = {};

    return data;
  }

  Map<String, dynamic>? parseElementMap(
      Element? rootElement, List<Selector> selectorList) {
    Map<String, dynamic> data = {};
    if (rootElement == null) return null;
    final subSelectorList = (selectorList);

    for (var selector in subSelectorList) {
      if (data[selector.key] != null) continue;
      String selectors = selector.selector ?? '';
      if (selector.multiple) {
        assert(selectors != '');
        final elements = rootElement.querySelectorAll(selectors);
        data[selector.key] = _parseElementMultiple(elements, selector);
      } else {
        Element? element = rootElement;
        if (selectors != '') element = rootElement.querySelector(selectors);
        data[selector.key] = _parseElementOne(element, selector);
      }
    }
    return data;
  }

  dynamic _parseElementMultiple(List<Element> elements, Selector selector) {
    List<dynamic>? list;
    assert(selector.autoType != SelectorType.json);
    switch (selector.autoType) {
      case SelectorType.element:
        {
          list = elements.map((element) {
            return parseElementMap(
                element, selectorList.getSubSelector(selector));
          }).toList();
          final subRequiredFields = selectorList
              .getSubSelector(selector)
              .where((field) => field.required);
          if (subRequiredFields.isNotEmpty) {
            list = list
                .where((map) => subRequiredFields
                    .every((field) => (map[field.key] != null)))
                .toList();
          }
          break;
        }
      case SelectorType.html:
      case SelectorType.text:
        {
          list = elements
              .map((element) => _parseElementOne(element, selector))
              .toList();
          break;
        }
      case SelectorType.attribute:
        {
          assert(selector.attribute != null);
          list = elements
              .map((element) => _parseElementOne(element, selector))
              .toList();
          break;
        }
      default:
        break;
    }
    list = _expression(list, selector);
    if (list != null && selector.required) {
      list = list.where((element) => element != null).toList();
    }
    return list;
  }

  dynamic _parseElementOne(Element? element, Selector selector) {
    dynamic value;
    if (element == null) {
      value = null;
    } else {
      switch (selector.autoType) {
        case SelectorType.element:
          {
            final subSelectors = selectorList.getSubSelector(selector);
            final subData = parseElementMap(element, subSelectors);
            if (subData == null) {
              value = null;
              break;
            }
            final subRequiredFields =
                subSelectors.where((field) => field.required);
            if (subRequiredFields
                .every((field) => subData[field.key] != null)) {
              value = subData;
            } else {
              value = null;
            }
            break;
          }
        case SelectorType.html:
          {
            value = element.innerHtml;
            break;
          }
        case SelectorType.text:
          {
            value = element.text;
            break;
          }
        case SelectorType.attribute:
          {
            assert(selector.attribute != null);
            value = element.getAttribute(selector.attribute!);
            break;
          }
        default:
          break;
      }
    }

    Map<String, dynamic> expressionRegexContext = {};
    if (value is String) {
      if (selector.regex != null) {
        final regex = selector.regex!;
        final pattern = regex.pattern;
        if (regex.replace == null) {
          final match = pattern.firstMatch(value);
          value = pattern.stringMatch(value);
          if (match != null) {
            for (int i = 0; i <= match.groupCount; i++) {
              final value = match.group(i);
              expressionRegexContext[r'$' + i.toString()] ??= value ?? '';
            }
          }
        } else {
          value = value.replaceAllMapped(pattern, (Match match) {
            String text = regex.replace!;
            for (int i = 0; i <= match.groupCount; i++) {
              final value = match.group(i);
              expressionRegexContext[r'$' + i.toString()] ??= value ?? '';
              final reg = RegExp(r'\$' + i.toString());
              text = text.replaceAll(reg, value ?? '');
            }
            return text;
          });
        }
      }
      if (selector.valueType == SelectorDataType.decimal) {
        value = double.tryParse(value);
      }
      if (selector.valueType == SelectorDataType.int) {
        value = int.tryParse(value);
      }
    }

    if (selector.valueType == SelectorDataType.bool) {
      value ??= false;
      if (value is String) value = value.trim() != '';
    }

    value = _expression(value, selector, expressionRegexContext);
    return value;
  }

  dynamic _expression(dynamic value, Selector selector,
      [Map<String, dynamic> selfContext = const {}]) {
    if (selector.expression == null) {
      return value;
    }
    try {
      final expression = Expression.parse(selector.expression!);
      final context = {
        'x': value,
        'value': value,
        ...expressionFunctions,
        ...selfContext,
        ...(selector.expressionContext ?? {})
      };
      final evaluator = const SelectorEvaluator();
      value = evaluator.eval(expression, context);
    } catch (error) {
      return null;
    }
    return value;
  }

  Map<String, dynamic> get expressionFunctions {
    return {
      "document": windowController.window!.document,
    };
  }
}

class ScraperController {
  ScraperRequestFunc request;

  static Future<String> defaultRequest(
      ScraperController controller, Scraper scraper, Uri uri) async {
    final httpClient = HttpClient();
    try {
      final request = await httpClient.getUrl(uri);
      final response = await request.close();
      var responseBody = await response.transform(Utf8Decoder()).join();
      httpClient.close();
      return responseBody;
    } catch (e) {
      httpClient.close();
      rethrow;
    }
  }

  ScraperController({this.request = defaultRequest});

  List<Scraper> scraperList = [];

  addYamlRules(String yaml) {
    var data = loadYaml(yaml);
    if (data is YamlMap) {
      data = data.toMap();
    }
    addJsonRule(data);
  }

  addJsonRule(Map<String, dynamic> data) {
    final scraper = Scraper.fromJson(data);
    scraperList.removeWhere((item) => item.name == scraper.name);
    scraperList.add(scraper);
  }

  Future<ScraperParser> loadUri(Uri uri) async {
    final scraper = scraperList.firstWhereOrNull((item) =>
        item.sites.firstWhereOrNull((site) => site.host == uri.host) != null);
    if (scraper == null) {
      throw "There are no supported rules. url: ${uri.toString()}";
    }
    final rule = scraper.rules.firstWhereOrNull((rule) =>
        rule.matches.firstWhereOrNull((e) {
          final url = uri.path + uri.query;
          return e.pattern.hasMatch(url);
        }) !=
        null);

    if (rule == null) {
      throw "There are no supported rules. url: ${uri.toString()}";
    }

    final text = await request(this, scraper, uri);
    return ScraperParser(this, scraper, rule, text);
  }
}

class SelectorEvaluator extends ExpressionEvaluator {
  const SelectorEvaluator();

  @override
  dynamic evalMemberExpression(
      MemberExpression expression, Map<String, dynamic> context) {
    var object = eval(expression.object, context);
    if (object is String) {
      if (expression.property.name == 'split') {
        return object.split;
      }
      if (expression.property.name == 'toInt') {
        return int.tryParse(object);
      }
      if (expression.property.name == 'toDouble') {
        return double.tryParse(object);
      }
    }

    if (object is List) {
      if (expression.property.name == 'join') {
        return object.join;
      }
    }
  }
}

extension YamlMapConverter on YamlMap {
  dynamic _convertNode(dynamic v) {
    if (v is YamlMap) {
      return (v as YamlMap).toMap();
    } else if (v is YamlList) {
      var list = <dynamic>[];
      for (var e in v) {
        list.add(_convertNode(e));
      }
      return list;
    } else {
      return v;
    }
  }

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{};
    nodes.forEach((k, v) {
      map[(k as YamlScalar).value.toString()] = _convertNode(v.value);
    });
    return map;
  }
}
