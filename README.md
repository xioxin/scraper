## Rule

```
selectors:
  - id: ratings
    parents: wrapper
    selector: .ir
    attribute: style
    regex:
      from: background-position:-?(\d+)px -(\d+)px;.*
      replace: $1,$2
    expression: "( 5 - x.split(',')[0].toInt / 16) - (x.split(',')[1].toInt > 1 ? 0.5 : 0)"
```

## Usage

```dart
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
```
