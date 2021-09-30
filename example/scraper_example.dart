import 'dart:io';

import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:scraper/scraper.dart';
import 'package:universal_html/controller.dart';

import 'domain_fronting.dart';


void main() async {
  final http = getHttpClient();

  var fileUri = Uri.file(Platform.script.toFilePath()).resolve('./eh.yaml');
  final ruleFile = File(fileUri.toFilePath());
  final List<Selector> rule = loadScraperYaml(ruleFile.readAsStringSync())!;

  final response = await http.get('https://e-hentai.org/');

  final controller = WindowController()
    ..openContent(response.data as String);

  final data = rule.parse(controller.window!.document.documentElement!);

  print(data);
}

Dio getHttpClient() {
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

