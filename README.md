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
| key    | type |  describe |
| :----- | :-- |  :---- |
| id | String | 输出字典时的key，配合parents确认子父级关系 |
| type | "text"\|"attribute"\|"attribute"\|null | element：元素，text: 元素中的文本，attribute：元素的属性 <br> 默认：如果有attribute参数不为空默认为attribute，否则为text |
| parents | List<String> \| String \| null | 父级id |
| selector | String \| null | 选择器 参考CSS选择器或JS的querySelector，空代表当前节点 |
| attribute | String | 获取元素属性 `<img src="a.jpg">` 这里的src |
| multiple | bool | 多个元素，输出类型为数组 |
| regex.from | String | 正则 |
| regex.flags | String \| null | 正则参数 igum |
| regex.replace | String \| null | 正则替换，为空将仅提取from匹配的内容 |
| valueType | "string" \| "bool" \| "int" \| "decimal" \| null | 默认为字符串。|
| expression | String | 表达式，类似于js、dart的语法 |
| expressionContext | Map<String, any> | 字典，表达式执行是可以获取这里的参数作为变量|
| children | List<Self> | 子字段，适合简单。建议使用 parents |


## Expression

TODO


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
