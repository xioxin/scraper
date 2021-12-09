import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';
import 'scraper_model.dart';
import 'package:collection/collection.dart';

import 'scraper_parser.dart';

typedef ScraperRequestFunc = Future<String> Function(
    ScraperController controller,
    Scraper scraper,
    Uri uri,
    Map<String, dynamic>? extra);

class ScraperController {
  ScraperRequestFunc request;

  static Future<String> defaultRequest(ScraperController controller,
      Scraper scraper, Uri uri, Map<String, dynamic>? extra) async {
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

  Future<ScraperParser> loadUri(Uri uri, [Map<String, dynamic>? extra]) async {
    final scraper = scraperList.firstWhereOrNull((item) =>
        item.sites.firstWhereOrNull((site) => site.host == uri.host) != null);
    if (scraper == null) {
      throw "There are no supported rules. url: ${uri.toString()}";
    }
    final rule = scraper.rules.firstWhereOrNull((rule) =>
        rule.matches.firstWhereOrNull((e) {
          String url = uri.path;
          if (uri.query != '') {
            url += '?' + uri.query;
          }
          return e.pattern.hasMatch(url);
        }) !=
        null);

    if (rule == null) {
      throw "There are no supported rules. url: ${uri.toString()}";
    }

    final text = await request(this, scraper, uri, extra);
    return ScraperParser(this, scraper, rule, text);
  }
}

extension YamlMapConverter on YamlMap {
  dynamic _convertNode(dynamic v) {
    if (v is YamlMap) {
      return v.toMap();
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
