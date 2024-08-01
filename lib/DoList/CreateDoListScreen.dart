import 'package:flutter/material.dart';
import 'package:gava/configure/configure.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:custom_sliding_segmented_control/custom_sliding_segmented_control.dart';
import 'package:gava/Firebase/FirebaseDBHelper.dart';


class CreateDoListScreen extends StatefulWidget {
  final DoList? doList;

  CreateDoListScreen({this.doList});

  @override
  _CreateDoListScreenState createState() => _CreateDoListScreenState();
}


class _CreateDoListScreenState extends State<CreateDoListScreen> {
  final TextEditingController _titleController = TextEditingController();

  String _selectedIcon = 'lightbulb.png';
  DateTime _selectedDate = DateTime.now();
  DateTime _selectedEndDate = DateTime.now();

  TimeOfDay _selectedTime = TimeOfDay.now();
  TimeOfDay _selectedEndTime = TimeOfDay.now();

  DateTime _tempSelectedDate = DateTime.now();
  DateTime _tempSelectedEndDate = DateTime.now();

  int _selectedImportance = 1;
  String _selectedTitle = '새로운 계획';

  List<DetailedDoList> detailedDoList = [];

  void _addDetailedDoList() {
    setState(() {
      detailedDoList.add(DetailedDoList(id: '', title: '', done: false));
    });
  }


  Future<void> _createDoList() async {

    if (_selectedTitle.isEmpty) {
      _showErrorDialog('계획 제목을 입력해주세요.'); // 'Please enter the plan title.'
      return;
    }
    if (_selectedIcon.isEmpty) {
      _showErrorDialog('아이콘을 선택해주세요.'); // 'Please select an icon.'
      return;
    }
    if (_selectedDate == null) {
      _showErrorDialog('시작 날짜를 선택해주세요.'); // 'Please select a start date.'
      return;
    }
    if (_selectedImportance == null) {
      _showErrorDialog('중요도를 선택해주세요.'); // 'Please select the importance.'
      return;
    }

    // Convert selected date and time to DateTime
    DateTime startDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    DateTime endDate = DateTime(
      _selectedEndDate.year,
      _selectedEndDate.month,
      _selectedEndDate.day,
      _selectedEndTime.hour,
      _selectedEndTime.minute,
    );

    DoList doList;
    if (widget.doList != null) {
      // Updating existing DoList
      doList = DoList(
        id: widget.doList!.id, // use existing id
        title: _selectedTitle,
        image: _selectedIcon,
        importance: _selectedImportance,
        done: false,
        startDate: _selectedDate.toIso8601String(),
        endDate: _selectedEndDate.toIso8601String(),
        doneTime: null,
        detailedDoList: detailedDoList,
      );

      // Update DoList in Firestore
      await FirebaseDBHelper().updateDoList(doList);

      for (var detailed in detailedDoList) {
        if (detailed.id.isEmpty) {
          // If the detailed list item is new (no id), save it to Firestore
          var savedDetailed = await FirebaseDBHelper().saveDetailedDoList(widget.doList!.id, detailed);
          // Optionally, update the local detailedDoList with savedDetailed
        } else {
          // If the detailed list item already has an id, update it
          await FirebaseDBHelper().updateDetailedDoList(widget.doList!.id, detailed.id, detailed);
        }
      }
    } else {
      // Creating new DoList
      doList = DoList(
        id: '', // leave empty to generate a new id
        title: _selectedTitle,
        image: _selectedIcon,
        importance: _selectedImportance,
        done: false,
        startDate: _selectedDate.toIso8601String(),
        endDate: _selectedEndDate.toIso8601String(),
        doneTime: null,
        detailedDoList: detailedDoList,
      );

      // Save new DoList to Firestore
      String doListId = await FirebaseDBHelper().saveDoList(doList);

      for (var detailed in detailedDoList) {
        debugPrint("detailedDoList : ${detailed.title}");
        await FirebaseDBHelper().saveDetailedDoList(doListId, detailed);
      }
    }

    Navigator.pop(context);

    // Maybe navigate to another screen or show a confirmation message
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

  void _initializeScreen() async {
    if (widget.doList != null) {
      _selectedTitle = widget.doList!.title;
      _selectedIcon = widget.doList!.image;
      _selectedImportance = widget.doList!.importance;
      DateTime startDate = DateTime.parse(widget.doList!.startDate);
      _selectedDate = startDate;
      _selectedTime = TimeOfDay(hour: startDate.hour, minute: startDate.minute);
      DateTime endDate = DateTime.parse(widget.doList!.endDate);
      _selectedEndDate = endDate;
      _selectedEndTime = TimeOfDay(hour: endDate.hour, minute: endDate.minute);

      // Fetch DetailedDoList items from Firestore
      detailedDoList = await FirebaseDBHelper().fetchDetailedDoList(widget.doList!.id);
      setState(() {}); // Update the UI with the fetched items
    }

    // Initialize the title controller with the selected title
    _titleController.text = _selectedTitle;
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
                      child: Text('계획 제목',style: TextStyle(color: TONED_DOWN_TEXTCOLOR),textAlign: TextAlign.start,),
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
            SizedBox(height: 20),
            Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: SECONDARY_COLOR
                ),
                child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20,vertical: 20),
                    child: Column(
                      children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('세부 계획',style: TextStyle(color: TONED_DOWN_TEXTCOLOR),textAlign: TextAlign.start,),
                              IconButton(
                                onPressed: _addDetailedDoList,
                                icon: Icon(Icons.add),color: Colors.white,)
                            ],
                          ),
                        ...List.generate(detailedDoList.length, (index) {
                          TextEditingController textEditingController = TextEditingController(text: detailedDoList[index].title);

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Stack(
                              alignment: Alignment.centerRight,
                              children: [
                                Row(
                                  children: [
                                    Theme(
                                      data: ThemeData(unselectedWidgetColor: Colors.white.withOpacity(0.5),),
                                      child: Checkbox(
                                        checkColor: Colors.white, // color of tick
                                        activeColor: Colors.transparent, // background color of checkbox
                                        value: detailedDoList[index].done,
                                        onChanged: (bool? value) {
                                          setState(() {
                                            detailedDoList[index].done = value!;
                                          });
                                        },
                                      ),
                                    ),
                                    Expanded(
                                      child: TextField(
                                        controller: textEditingController,
                                        onChanged: (newValue) {
                                          detailedDoList[index].title = newValue;
                                        },
                                        style: TextStyle(color: Colors.white),
                                        decoration: InputDecoration(
                                          hintText: '',
                                          border: InputBorder.none,
                                          filled: false,
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(color: Colors.white10),
                                          ),
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(color: Colors.blue),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: Icon(Icons.remove, color: Colors.white.withOpacity(0.5)),
                                  onPressed: () {
                                    setState(() {
                                      detailedDoList.removeAt(index);
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    )
                )
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
                        items: <String>['car.png', 'cart.png', 'coin.png', 'folder.png', 'hamburger.png','heart.png','lightbulb.png','magnifyingGlass.png','memo.png','shoe.png','trophy.png'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Center( // Use Center to align the image
                              child: Image.asset('assets/$value', width: 40, height: 40),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedIcon = newValue!;
                          });
                        },
                        borderRadius: BorderRadius.circular(20),
                        alignment: Alignment.center,
                        // padding: EdgeInsets.symmetric(horizontal: 10),
                        // style: TextStyle(color: Colors.white, fontSize: 16),
                        dropdownColor: TERTIARY_COLOR,
                      ),
                    ),
                  ],
                ),
              ),
            ),


            SizedBox(height: 20),
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
                      '시작 날짜',
                      style: TextStyle(color: TONED_DOWN_TEXTCOLOR),
                    ),
                    InkWell(
                      onTap: () {
                        showModalBottomSheet(
                          backgroundColor: Colors.transparent,
                          context: context,
                          builder: (BuildContext context) {
                            return Container(
                              decoration: BoxDecoration(
                                color: SECONDARY_COLOR,
                                borderRadius: BorderRadius.only(topRight: Radius.circular(23), topLeft: Radius.circular(23))
                              ),
                              height: 300,
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 40, horizontal: 20),
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
                                  calendarFormat: CalendarFormat.week,
                                  onDaySelected: (selectedDay, focusedDay) {
                                    setState(() {
                                      _selectedDate = selectedDay;
                                    });
                                    Navigator.pop(context);
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
                                      borderRadius: BorderRadius.circular(23),
                                    ),
                                    selectedTextStyle: TextStyle(color: Colors.white),
                                  ),
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
                            '${DateFormat('yyyy.MM.dd').format(_selectedDate)}',
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
            SizedBox(height: 20),
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
                      '종료 날짜',
                      style: TextStyle(color: TONED_DOWN_TEXTCOLOR),
                    ),
                    InkWell(
                      onTap: () {
                        showModalBottomSheet(
                          backgroundColor: Colors.transparent,
                          context: context,
                          builder: (BuildContext context) {
                            return Container(
                              decoration: BoxDecoration(
                                  color: SECONDARY_COLOR,
                                  borderRadius: BorderRadius.only(topRight: Radius.circular(23), topLeft: Radius.circular(23))
                              ),
                              height: 300,
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 40, horizontal: 20),
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
                                  calendarFormat: CalendarFormat.week,
                                  onDaySelected: (selectedDay, focusedDay) {
                                    setState(() {
                                      _selectedEndDate = selectedDay;
                                    });
                                    Navigator.pop(context);
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
                                      borderRadius: BorderRadius.circular(23),
                                    ),
                                    selectedTextStyle: TextStyle(color: Colors.white),
                                  ),
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
                            '${DateFormat('yyyy.MM.dd').format(_selectedEndDate)}',
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
                      '계획 중요도',
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
                                                innerPadding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
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
                  child: Text('계획 만들기', style: TextStyle(color: Colors.white, fontSize: 18),),
                  onPressed: _createDoList,
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
