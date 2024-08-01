import 'package:flutter/material.dart';
import 'package:gava/configure/configure.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:custom_sliding_segmented_control/custom_sliding_segmented_control.dart';
import 'package:gava/Firebase/FirebaseDBHelper.dart';
import 'package:gava/configure/InlineDatePicker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NewScheduleScreen extends StatefulWidget {

  final ScheduleData? scheduleData;

  NewScheduleScreen({this.scheduleData});

  @override
  _NewScheduleScreenState createState() => _NewScheduleScreenState();
}


class _NewScheduleScreenState extends State<NewScheduleScreen> {
  final TextEditingController _titleController = TextEditingController();

  String _selectedIcon = 'chick1.png';
  DateTime _selectedDate = DateTime.now();
  DateTime _selectedEndDate = DateTime.now();

  TimeOfDay _selectedTime = TimeOfDay.now();
  TimeOfDay _selectedEndTime = TimeOfDay.now();

  bool _isTimeSettingEnabled = false;
  bool _showStartDatePicker = false;
  bool _showEndDatePicker = false;

  bool _showStartTimePicker = false;
  bool _showEndTimePicker = false;

  DateTime _tempSelectedDate = DateTime.now();
  DateTime _tempSelectedEndDate = DateTime.now();

  int _selectedImportance = 1;
  String _selectedTitle = '새로운 일정';

  List<DetailedDoList> detailedDoList = [];
  String get userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> addNewScheduleToFirestore() async {
    // Convert DateTime to String in the format yyyy-MM-dd
    String formattedStartDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    String formattedEndDate = DateFormat('yyyy-MM-dd').format(_selectedEndDate);

    // Optional start and end times
    String? startTimeString;
    String? endTimeString;

    if (_isTimeSettingEnabled) {
      startTimeString = _selectedTime.format(context);
      endTimeString = _selectedEndTime.format(context);
    }

    Map<String, dynamic> scheduleData = {
      'title': _selectedTitle,
      'image': _selectedIcon,
      'importance': _selectedImportance,
      'startDate': formattedStartDate,
      'endDate': formattedEndDate,
      'notification': false,
    };

    // Add start and end times if they are set
    if (startTimeString != null) scheduleData['startTime'] = startTimeString;
    if (endTimeString != null) scheduleData['endTime'] = endTimeString;

    try {
      if (widget.scheduleData == null) {
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(userId) // Make sure you have the correct userId
            .collection('Schedule')
            .add(scheduleData);
        print('Schedule added successfully');
      } else {
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(userId)
            .collection('Schedule')
            .doc(widget.scheduleData!.docId)
            .update(scheduleData);
        print('Schedule updated successfully');
      }
      Navigator.pop(context, true);
    } catch (e) {
      print('Error adding schedule: $e');
      _showErrorDialog('다시 확인해주세요!: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('잠시만요!'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('확인'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showCustomAlertDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Confirmation'),
          content: Text('Are you sure you want to delete this item?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                setState(() {
                  detailedDoList.removeAt(index);
                });
                if (mounted) {
                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  void _initializeScreen() {
    if (widget.scheduleData != null) {
      _selectedTitle = widget.scheduleData!.title;
      _titleController.text = _selectedTitle;

      _selectedIcon = widget.scheduleData!.image;
      _selectedImportance = widget.scheduleData!.importance;

      // Assuming startDate and endDate are stored as 'yyyy-MM-dd' format in ScheduleData
      _selectedDate = DateFormat('yyyy-MM-dd').parse(widget.scheduleData!.startDate);
      _selectedEndDate = DateFormat('yyyy-MM-dd').parse(widget.scheduleData!.endDate);

      // If startTime and endTime are stored in ScheduleData and not null
      if (widget.scheduleData!.startTime != null) {
        _selectedTime = _timeFromString(widget.scheduleData!.startTime!);
        _isTimeSettingEnabled = true;
      }
      if (widget.scheduleData!.endTime != null) {
        _selectedEndTime = _timeFromString(widget.scheduleData!.endTime!);
      }
    }
  }

  TimeOfDay _timeFromString(String timeString) {
    try {
      final timeParts = timeString.split(':');
      if (timeParts.length != 2) {
        throw FormatException('Invalid time format');
      }

      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      // Handle the error, maybe log it or set a default value
      print('Error parsing time: $e');
      return TimeOfDay.now(); // Default value in case of error
    }
  }


  void _validateAndSetDateTime(DateTime selectedStartDate, TimeOfDay selectedStartTime, DateTime selectedEndDate, TimeOfDay selectedEndTime) {
    DateTime startDateTime = DateTime(
      selectedStartDate.year,
      selectedStartDate.month,
      selectedStartDate.day,
      selectedStartTime.hour,
      selectedStartTime.minute,
    );

    DateTime endDateTime = DateTime(
      selectedEndDate.year,
      selectedEndDate.month,
      selectedEndDate.day,
      selectedEndTime.hour,
      selectedEndTime.minute,
    );

    if (startDateTime.isAfter(endDateTime)) {
      if (_isTimeSettingEnabled) {
        // Delay the end time by 1 hour if time setting is enabled
        DateTime newEndDateTime = startDateTime.add(Duration(hours: 1));
        _selectedEndDate = newEndDateTime;
        _selectedEndTime = TimeOfDay(hour: newEndDateTime.hour, minute: newEndDateTime.minute);
      } else {
        // Delay the end date by 1 day if only date setting is enabled
        _selectedEndDate = selectedStartDate.add(Duration(days: 1));
      }
    } else {
      _selectedDate = selectedStartDate;
      _selectedTime = selectedStartTime;
      _selectedEndDate = selectedEndDate;
      _selectedEndTime = selectedEndTime;
    }

    setState(() {});
  }



  @override
  void dispose() {
    super.dispose();
    _titleController.dispose();

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${_selectedTitle}',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
        ),
        centerTitle: true, // This will center the title
        backgroundColor: Colors.transparent,
        elevation: 0, // Removes the shadow under the AppBar
      ),

      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(23.0),
        child: ListView(
          children: [
            Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: SECONDARY_COLOR
                ),
                child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20,vertical: 30),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: Text('일정 제목',style: TextStyle(color: TONED_DOWN_TEXTCOLOR),textAlign: TextAlign.start,),
                        ),
                        TextField(
                          controller: _titleController,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: TONED_DOWN_TEXTCOLOR,),
                            ),
                          ),
                          onChanged: (newValue) {
                            setState(() {
                              _selectedTitle = newValue; // Update _selectedTitle with the new value
                            });
                          },
                        ),
                      ],
                    )
                )
            ),
            SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Color(0xff121212),
                borderRadius: BorderRadius.circular(23)
              ),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(23),
                      color: SECONDARY_COLOR,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '시간 설정',
                            style: TextStyle(color: TONED_DOWN_TEXTCOLOR),
                          ),
                          CupertinoSwitch(
                            value: _isTimeSettingEnabled,
                            onChanged: (newValue) {
                              setState(() {
                                _isTimeSettingEnabled = newValue;
                              });
                            },
                            activeColor: PRIMARY_COLOR,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: InkWell(
                      onTap: (){
                        setState(() {
                          _showStartTimePicker = !_showStartTimePicker;
                        });
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '시작',
                            style: TextStyle(color: TONED_DOWN_TEXTCOLOR),
                          ),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _showStartDatePicker = !_showStartDatePicker;
                              });
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 23,vertical: 12),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: TERTIARY_COLOR
                                  ),
                                  child: Text(
                                    '${DateFormat('yy/MM/dd').format(_selectedDate)}',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ),
                                SizedBox(width: 10,),
                                if (_isTimeSettingEnabled)
                                  InkWell(
                                    onTap: () async {
                                      setState(() {
                                        _showStartTimePicker = !_showStartTimePicker;
                                      });
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 23, vertical: 12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: TERTIARY_COLOR,
                                      ),
                                      child: Text(
                                        _selectedTime.format(context),
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_showStartDatePicker)
                    Container(
                      // height: 300,
                      child: TableCalendar(
                        daysOfWeekStyle: DaysOfWeekStyle( weekdayStyle: TextStyle(color: Colors.white), weekendStyle: TextStyle(color: Colors.blue)),
                        headerStyle: HeaderStyle(
                            titleCentered: true,
                            titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
                            leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white,),
                            rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white,),
                            formatButtonVisible: false
                        ),
                        firstDay: DateTime.utc(2010, 10, 16),
                        lastDay: DateTime.utc(2030, 3, 14),
                        focusedDay: _selectedDate,
                        locale: 'ko_KR',
                        calendarFormat: CalendarFormat.month,
                        onDaySelected: (selectedDay, focusedDay) {
                          _validateAndSetDateTime(selectedDay, _selectedTime, _selectedEndDate, _selectedEndTime);
                        },

                        selectedDayPredicate: (day) {
                          return isSameDay(_selectedDate, day);
                        },
                        calendarStyle: CalendarStyle(
                          isTodayHighlighted: false,
                          tablePadding: EdgeInsets.symmetric(horizontal: 20),
                          defaultTextStyle: TextStyle(color: Colors.white, fontSize: 18),
                          // rowDecoration: BoxDecoration(color: TERTIARY_COLOR,borderRadius: BorderRadius.circular(23)),
                          cellPadding: EdgeInsets.symmetric(horizontal: 5,vertical: 2),
                          selectedDecoration: BoxDecoration(
                            color: PRIMARY_COLOR,
                            shape: BoxShape.circle,
                          ),
                          selectedTextStyle: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  if (_showStartTimePicker)
                    Container(
                      height: 140,
                      child: CupertinoTheme(
                        data: CupertinoThemeData(
                          textTheme: CupertinoTextThemeData(
                            dateTimePickerTextStyle: TextStyle(
                              color: Colors.white
                            ),
                          )
                        ),
                        child: CupertinoDatePicker(
                          minuteInterval: 10,
                          mode: CupertinoDatePickerMode.time,
                          initialDateTime: DateTime(
                            DateTime.now().year,
                            DateTime.now().month,
                            DateTime.now().day,
                            _selectedTime.hour,
                              (_selectedTime.minute ~/ 10) * 10,
                          ),
                          onDateTimeChanged: (DateTime newDateTime) {
                            TimeOfDay newTime = TimeOfDay.fromDateTime(newDateTime);
                            _validateAndSetDateTime(_selectedDate, newTime, _selectedEndDate, _selectedEndTime);
                          },
                        ),
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                    child: Divider(color:  Color(0xff252525),),
                  ),
                  Padding(
                    padding: EdgeInsets.only(right: 20, left: 20, top: 10, bottom: 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '종료',
                          style: TextStyle(color: TONED_DOWN_TEXTCOLOR),
                        ),
                        InkWell(
                          onTap: () async {
                            setState(() {
                              // Toggle the visibility
                              _showEndDatePicker = !_showEndDatePicker;
                            });
                            },
                          child:  Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 18,vertical: 12),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: TERTIARY_COLOR
                                ),
                                child: Text(
                                  '${DateFormat('yy/MM/dd').format(_selectedEndDate)}',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                              SizedBox(width: 10,),
                              if (_isTimeSettingEnabled)
                                InkWell(
                                  onTap: () async {
                                    setState(() {
                                      // Toggle the visibility
                                      _showEndTimePicker = !_showEndTimePicker;
                                    });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: TERTIARY_COLOR,
                                    ),
                                    child: Text(
                                      _selectedEndTime.format(context),
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ),
                                ),
                            ],
                          )
                        ),
                      ],
                    ),
                  ),
                  if (_showEndDatePicker)
                    Container(
                      // height: 300,
                      child: TableCalendar(
                        daysOfWeekStyle: DaysOfWeekStyle( weekdayStyle: TextStyle(color: Colors.white), weekendStyle: TextStyle(color: Colors.blue)),
                        headerStyle: HeaderStyle(
                            titleCentered: true,
                            titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
                            leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white,),
                            rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white,),
                            formatButtonVisible: false
                        ),
                        firstDay: DateTime.utc(2010, 10, 16),
                        lastDay: DateTime.utc(2030, 3, 14),
                        focusedDay: _selectedEndDate,
                        locale: 'ko_KR',
                        calendarFormat: CalendarFormat.month,
                        onDaySelected: (selectedDay, focusedDay) {
                          _validateAndSetDateTime(_selectedDate, _selectedTime, selectedDay, _selectedEndTime);
                        },
                        selectedDayPredicate: (day) {
                          return isSameDay(_selectedEndDate, day);
                        },
                        calendarStyle: CalendarStyle(
                          isTodayHighlighted: false,
                          tablePadding: EdgeInsets.symmetric(horizontal: 20),
                          defaultTextStyle: TextStyle(color: Colors.white, fontSize: 18),
                          // rowDecoration: BoxDecoration(color: TERTIARY_COLOR,borderRadius: BorderRadius.circular(23)),
                          cellPadding: EdgeInsets.symmetric(horizontal: 5,vertical: 2),
                          selectedDecoration: BoxDecoration(
                            color: PRIMARY_COLOR,
                            shape: BoxShape.circle,
                          ),
                          selectedTextStyle: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  if (_showEndTimePicker)
                    Container(
                      height: 140,
                      child: CupertinoTheme(
                        data: CupertinoThemeData(
                            textTheme: CupertinoTextThemeData(
                              dateTimePickerTextStyle: TextStyle(
                                  color: Colors.white
                              ),
                            )
                        ),
                        child: CupertinoDatePicker(
                          minuteInterval: 10,
                          mode: CupertinoDatePickerMode.time,
                          initialDateTime: DateTime(
                            DateTime.now().year,
                            DateTime.now().month,
                            DateTime.now().day,
                            _selectedEndTime.hour,
                            (_selectedEndTime.minute ~/ 10) * 10,
                          ),
                          onDateTimeChanged: (DateTime newDateTime) {
                            TimeOfDay newTime = TimeOfDay.fromDateTime(newDateTime);
                            _validateAndSetDateTime(_selectedDate, _selectedTime, _selectedEndDate, newTime);
                          },

                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 20,),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(23),
                color: SECONDARY_COLOR,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '아이콘 선택',
                      style: TextStyle(color: TONED_DOWN_TEXTCOLOR),
                    ),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedIcon,
                        icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                        items: <String>['car.png', 'cart.png', 'coin.png', 'folder.png', 'hamburger.png','heart.png','lightbulb.png','magnifyingGlass.png','memo.png','setting.png','shoe.png','trophy.png'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Image.asset('assets/$value', width: 40, height: 40), // Display images from assets
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedIcon = newValue!;
                          });
                        },
                        style: TextStyle(color: Colors.white, fontSize: 16),
                        dropdownColor: SECONDARY_COLOR,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(23),
                color: SECONDARY_COLOR,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '일정 중요도',
                      style: TextStyle(color: TONED_DOWN_TEXTCOLOR),
                    ),
                    InkWell(
                      onTap: () async {
                        showModalBottomSheet(
                          backgroundColor: Colors.transparent,
                          context: context,
                          builder: (BuildContext context) {
                            return Container(
                              decoration: BoxDecoration(
                                  color: SECONDARY_COLOR,
                                  borderRadius: BorderRadius.only(topRight: Radius.circular(23), topLeft: Radius.circular(23))
                              ),
                              height: 350,
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                                child: Wrap(
                                  children: <Widget>[
                                    ListTile(
                                      title: Center(
                                        child: Text('계획의 중요도',style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600),),
                                      ),
                                      subtitle: Center(
                                          child: Text('중요도에 비례해 계획박스의 크기가 결정됩니다', style: TextStyle(color: TONED_DOWN_TEXTCOLOR),)
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(23),
                                        color: SECONDARY_COLOR,
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.only(right: 20, left: 20, top: 0, bottom: 20),
                                        child: Column(
                                          children: [
                                            SizedBox(height: 10), // Add some spacing
                                            Center(
                                              child: CustomSlidingSegmentedControl<int>(
                                                innerPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                                                initialValue: _selectedImportance,
                                                children: {
                                                  1: Container(
                                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                                    child: Text(
                                                      '하',
                                                      style: TextStyle(
                                                        color: TONED_DOWN_TEXTCOLOR,
                                                      ),
                                                    ),
                                                  ),
                                                  2: Container(
                                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                                    child: Text(
                                                      '중',
                                                      style: TextStyle(
                                                        color:TONED_DOWN_TEXTCOLOR,
                                                      ),
                                                    ),
                                                  ),
                                                  3: Container(
                                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                                    child: Text(
                                                      '상',
                                                      style: TextStyle(
                                                        color: TONED_DOWN_TEXTCOLOR,
                                                      ),
                                                    ),
                                                  ),
                                                },
                                                onValueChanged: (int newValue) {
                                                  setState(() {
                                                    _selectedImportance = newValue;
                                                  });
                                                },
                                                decoration: BoxDecoration(
                                                  color: TERTIARY_COLOR,
                                                  borderRadius: BorderRadius.circular(30),
                                                ),
                                                thumbDecoration: BoxDecoration(
                                                  color: Color(0xff343434),
                                                  borderRadius: BorderRadius.circular(30),
                                                ),
                                              ),
                                            ),
                                            // ... other widgets like the confirm button ...
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 30,),
                                    Center(
                                      child: SizedBox(
                                          width: MediaQuery.of(context).size.width - 80,
                                          child: Container(
                                            height: 60,
                                            decoration: BoxDecoration(
                                                color: PRIMARY_COLOR,
                                                borderRadius: BorderRadius.circular(32)
                                            ),
                                            child: TextButton(
                                              child: Text('확인', style: TextStyle(color: Colors.white),),
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                            ),
                                          )
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            getImportanceText(_selectedImportance),
                            style: TextStyle(color: Colors.white70),
                          ),
                          Icon(
                            Icons.arrow_drop_down,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20,),
            SizedBox(
                width: double.infinity,
                child: Container(
                  height: 72,
                  decoration: BoxDecoration(
                      color: PRIMARY_COLOR,
                      borderRadius: BorderRadius.circular(32)
                  ),
                  child: TextButton(
                    child: Text('일정 만들기', style: TextStyle(color: Colors.white, fontSize: 18),),
                    onPressed: addNewScheduleToFirestore,
                  ),
                )
            ),
          ],
        ),
      ),
    );
  }

  String getImportanceText(int importance) {
    switch (importance) {
      case 1:
        return '하';
      case 2:
        return '중';
      case 3:
        return '상';
      default:
        return '선택';
    }
  }


}
