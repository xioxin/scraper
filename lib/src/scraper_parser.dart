import 'dart:convert';
import 'dart:io';

import 'package:expressions/expressions.dart';
import 'package:universal_html/controller.dart';
import 'package:universal_html/html.dart';
import 'package:uri/uri.dart';
import 'package:yaml/yaml.dart';
import 'scraper_controller.dart';
import 'scraper_model.dart';
import 'package:collection/collection.dart';

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
    selectorList = rule.selectors ?? [];
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
        data[selector.key] = _parseElementMultiple(elements, selector, data);
      } else {
        Element? element = rootElement;
        if (selectors != '') element = rootElement.querySelector(selectors);
        data[selector.key] = _parseElementOne(element, selector, data);
      }
    }
    return data;
  }

  dynamic _parseElementMultiple(
      List<Element> elements, Selector selector, dynamic parentData) {
    dynamic list;
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
      case SelectorType.attribute:
      case SelectorType.value:
        {
          assert(selector.attribute != null);
          list = elements
              .map((element) => _parseElementOne(element, selector, parentData))
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

  dynamic _parseElementOne(
      Element? element, Selector selector, dynamic parentData) {
    dynamic value;
    if (element == null) {
      value = null;
    } else {
      switch (selector.autoType) {
        case SelectorType.value:
          value = selector.value;
          break;
        case SelectorType.element:
          {
            final subSelectors = selectorList.getSubSelector(selector);
            final subData = parseElementMap(element, subSelectors);
            if (subData == null) {
              value = null;
              break;
            }
            if (subData is Map) {
              final subRequiredFields =
                  subSelectors.where((field) => field.required);
              if (subRequiredFields
                  .every((field) => subData[field.key] != null)) {
                value = subData;
              } else {
                value = null;
              }
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
    }
    value = _expression(
        value, selector, {...expressionRegexContext, 'this': parentData});
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
      "RegExp": (String from, [String? flags]) {
        final multiLine = flags?.toLowerCase().contains('m') ?? false;
        final caseSensitive = !(flags?.toLowerCase().contains('i') ?? false);
        final dotAll = flags?.toLowerCase().contains('g') ?? false;
        final unicode = flags?.toLowerCase().contains('u') ?? false;
        return RegExp(from,
            multiLine: multiLine,
            caseSensitive: caseSensitive,
            unicode: unicode,
            dotAll: dotAll);
      },
      "UriTemplateExpand": (String uriTemplate, Map<String, Object?> data) {
        return UriTemplate(uriTemplate).expand(data);
      },
      "UriTemplate": (String uriTemplate) {
        return (Map<String, Object?> data) =>
            UriTemplate(uriTemplate).expand(data);
      },
      ...scraper.constants,
    };
  }
}

class SelectorEvaluator extends ExpressionEvaluator {
  const SelectorEvaluator();

  @override
  dynamic evalMemberExpression(
      MemberExpression expression, Map<String, dynamic> context) {
    var object = eval(expression.object, context);
    final name = expression.property.name;

    if (object == null) return null;
    if (object is String) {
      if (name == 'split') return object.split;
      if (name == 'trim') return object.trim;
      if (name == 'contains') return object.contains;
      if (name == 'toInt') return () => int.tryParse(object);
      if (name == 'toDouble') return () => double.tryParse(object);
      if (name == 'toBool') return () => object.trim() != '';
      if (name == 'isEmpty') return object.isEmpty;
      if (name == 'isNotEmpty') return object.isNotEmpty;
      if (name == 'length') return () => object.length;
      if (name == 'toDataTime') return () => DateTime.parse(object);
    }

    if (object is List) {
      if (name == 'join') return object.join;
      if (name == 'toBool') return object.isNotEmpty;
      if (name == 'isEmpty') return object.isEmpty;
      if (name == 'isNotEmpty') return object.isNotEmpty;
      if (name == 'last') return object.last;
      if (name == 'first') return object.first;
      if (name == 'contains') return object.contains;
      if (name == 'getRange') {
        return (int start, int end) => object.getRange(start, end).toList();
      }
      if (name == 'reversed') return object.reversed.toList();
      if (name == 'length') return () => object.length;
    }

    if (object is Map) {
      if (object.containsKey(expression.property.name)) {
        return object[expression.property.name];
      }
      if (name == 'toBool') return object.isNotEmpty;
      if (name == 'isEmpty') return object.isEmpty;
      if (name == 'isNotEmpty') return object.isNotEmpty;
      if (name == 'length') return () => object.length;
    }

    if (name == 'toString') return object.toString;

    print("======== eval NULL ======= \n"
        "expression: $expression\n"
        "property.name: $name\n"
        "object: $object\n"
        "context: $context\n");
  }
}

stringToDateTime(String dateString) {
  // todo 模糊的日期转换
}
