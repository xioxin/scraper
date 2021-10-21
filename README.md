## Screenshot

![Rule](https://user-images.githubusercontent.com/5716100/138303844-68aa9e1c-772b-4bf2-b1c3-98f9d913ca4b.png)


![Result](https://user-images.githubusercontent.com/5716100/138303867-277b711f-8377-44dd-ac95-add7e1707160.png)




<!---
### 结构已经大改 以下内容为上个版本的结构

```
selectors:
  - id: ratings
    parents: wrapper
    selector: .ir
    attribute: style
    regex: background-position:-?(\d+)px -(\d+)px;.*
    expression: "( 5 - $1.toInt / 16) - ($2.toInt > 1 ? 0.5 : 0)"
```

查看完整规则： <https://github.com/xioxin/scraper/blob/main/example/eh.yaml>

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
| children | List<Self> | 子字段。复杂的建议使用 parents |

  
## Expression

* String.split(pattern)
* String.toDouble
* String.toInt

* List.join(separator)

* document TODO

## Usage

```dart
void main() async {
  var fileUri = Uri.file(Platform.script.toFilePath()).resolve('./eh.yaml');
  final ruleFile = File(fileUri.toFilePath());

  final http = getHttpClient();
  final response = await http.get('https://e-----ai.org/');

  final scraper = Scraper();
  scraper.loadRulesYaml(ruleFile.readAsStringSync());
  scraper.loadContent(response.data as String);

  final data = scraper.parse();
  print(JsonEncoder.withIndent('  ').convert(data));
}
```

![image](https://user-images.githubusercontent.com/5716100/135469425-baf27b78-c308-4d99-bacd-9f2ca5981df0.png)

---->
