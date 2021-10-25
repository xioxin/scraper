import 'dart:convert';
import 'dart:io';

import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:scraper/scraper.dart';
import 'package:universal_html/controller.dart';

import '../example/domain_fronting.dart';
import 'package:uri/uri.dart';

// dart bin/scraper.dart https://e-hentai.org/non-h
// dart bin/scraper.dart https://e-hentai.org/g/2029065/1e6df31ab8/
// dart bin/scraper.dart https://e-hentai.org/g/2042088/a26bdd9ad0/

void main(List<String> arguments) async {
  var fileUri =
      Uri.file(Platform.script.toFilePath()).resolve('../rules/eh.yaml');
  final ruleFile = File(fileUri.toFilePath());
  final dio = getDio();

  final controller = ScraperController(
      request: (ScraperController controller, Scraper scraper, Uri uri) async {
    final response = await dio.getUri(uri);
    return response.data;
  });

  controller.addYamlRules(ruleFile.readAsStringSync());
  final parser = await controller.loadUri(Uri.parse(arguments.first));
  print(JsonEncoder.withIndent('  ', myEncode).convert(parser.parse()));
  dio.close();
}

Dio getDio() {
  final dio = Dio();
  dio.options.headers = {
    'cookie': 'sl=dm_2',
    'User-Agent':
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/93.0.4577.82 Safari/537.36',
  };

  final hosts = {'e-hentai.org': '37.48.89.16'};

  final domainFronting = DomainFronting(
    dnsLookup: (host) => hosts[host],
  );

  (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
      (HttpClient client) {
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) {
      return hosts.containsValue(host);
    };
  };

  domainFronting.bind(dio);
  return dio;
}

dynamic myEncode(dynamic item) {
  if (item is DateTime) {
    return item.toIso8601String();
  }
  return item;
}
