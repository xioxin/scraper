import 'package:expressions/expressions.dart';
import 'package:universal_html/html.dart';
import 'package:yaml/yaml.dart';
import 'scraper_model.dart';

List<Selector>? loadScraperYaml(String yaml) {
  final data = loadYaml(yaml);
  List<Selector>? selectors;
  if (data is Map && data.containsKey('selectors')) {
    final selectorsJson = data['selectors'];
    if (selectorsJson is List) {
      selectors = selectorsJson
          .map((json) {
            return Selector.fromJson(Map<String, dynamic>.from(json));
          })
          .whereType<Selector>()
          .toList();
    }
  }
  return selectors;
}


extension SelectorList on List<Selector> {
  List<Selector> _getSubSelector(Selector selector) {
    return [
      ...selector.children ?? [],
      ...where((element) => element.parents?.contains(selector.id) ?? false)
    ];
  }

  Map<String, dynamic> parse(Element rootElement, {String? rootId, List<Selector>? selectorList}) {
    Map<String, dynamic> data = {};
    selectorList ??= where((item) => rootId == null
        ? item.parents == null
        : (item.parents?.contains(rootId) ?? false)).toList();
    for (var selector in selectorList) {
      if (data[selector.id] != null) continue;
      String selectors = selector.selector ?? '';
      if (selector.multiple) {
        final elements = rootElement.querySelectorAll(selectors);
        data[selector.id] = _parseMultiple(elements, selector);
      } else {
        Element? element = rootElement;
        if (selectors != '') element = rootElement.querySelector(selectors);
        data[selector.id] = _parseOne(element, selector);
      }
    }
    return data;
  }

  dynamic _parseMultiple(List<Element> elements, Selector selector) {
    List<dynamic>? list;
    switch (selector.autoType) {
      case SelectorType.element:
        {
          list = elements.map((element) {
            return parse(element, selectorList: _getSubSelector(selector));
          }).toList();
          final subRequiredFields = _getSubSelector(selector).where((field) => field.required);
          if (subRequiredFields.isNotEmpty) {
            list = list
                .where((map) =>
                subRequiredFields.every((field) => (map[field.id] != null)))
                .toList();
          }
          break;
        }
      case SelectorType.text:
        {
          list =
              elements.map((element) => _parseOne(element, selector)).toList();
          break;
        }
      case SelectorType.attribute:
        {
          assert(selector.attribute != null);
          list =
              elements.map((element) => _parseOne(element, selector)).toList();
          break;
        }
      default:
        break;
    }
    list = _expression(list, selector);
    if (list != null && selector.required){
      list = list.where((element) => element != null).toList();
    }
    return list;
  }

  dynamic _parseOne(Element? element, Selector selector) {
    dynamic value;
    if (element == null) {
      value = null;
    } else {
      switch (selector.autoType) {
        case SelectorType.element:
          {
            final subData = parse(element, selectorList: _getSubSelector(selector));
            final subRequiredFields = _getSubSelector(selector).where((field) => field.required);
            if (subRequiredFields.every((field) => subData[field.id] != null)) {
              value = subData;
            } else {
              value = null;
            }
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
        bool multiLine = false;
        bool caseSensitive = true;
        bool unicode = false;
        bool dotAll = false;
        if (regex.flags != null) {
          multiLine = regex.flags!.toLowerCase().contains('m');
          caseSensitive = !regex.flags!.toLowerCase().contains('i');
          dotAll = regex.flags!.toLowerCase().contains('g');
          unicode = regex.flags!.toLowerCase().contains('u');
        }
        final pattern = RegExp(regex.from,
            multiLine: multiLine,
            caseSensitive: caseSensitive,
            unicode: unicode,
            dotAll: dotAll);
        if (regex.replace == null) {
          final match = pattern.firstMatch(value);
          value = pattern.stringMatch(value);
          if(match != null) {
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

  dynamic _expression(dynamic value, Selector selector, [Map<String, dynamic> selfContext = const {}]) {
    if (selector.expression == null) {
      return value;
    }
    try {
      final expression = Expression.parse(selector.expression!);
      final context = {
        'x': value,
        'value': value,
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

    if(object is List) {
      if (expression.property.name == 'join') {
        return object.join;
      }
    }
  }
}
