import 'package:day/day.dart';

typedef DateTimeParseFun = DateTime? Function(String time);

void main() {
  print(Day.fromString("21 August 2021, 08:42"));

  // final List<DateTimeParseFun> r = [
  //   (time) {

  //   }
  // ];
}
