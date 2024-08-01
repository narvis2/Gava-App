import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

class InlineDatePicker extends StatefulWidget {
  final DateTime initialDate;
  final ValueChanged<DateTime> onDateTimeChanged;

  InlineDatePicker({
    Key? key,
    required this.initialDate,
    required this.onDateTimeChanged,
  }) : super(key: key);

  @override
  _InlineDatePickerState createState() => _InlineDatePickerState();
}

class _InlineDatePickerState extends State<InlineDatePicker> {
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text(DateFormat('yyyy.MM.dd').format(selectedDate)),
          trailing: Icon(Icons.arrow_drop_down),
          onTap: () {
            setState(() {
              // Toggle the visibility of the date picker
            });
          },
        ),
        AnimatedCrossFade(
          firstChild: Container(),
          secondChild: Container(
            height: MediaQuery.of(context).size.height / 3,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              initialDateTime: selectedDate,
              onDateTimeChanged: (DateTime newDate) {
                widget.onDateTimeChanged(newDate);
                setState(() {
                  selectedDate = newDate;
                });
              },
            ),
          ),
          crossFadeState: selectedDate.isAtSameMomentAs(widget.initialDate)
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 300),
        ),
      ],
    );
  }
}
