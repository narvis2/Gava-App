import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:gava/configure/configure.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'dart:math';
import 'package:gava/calendar/NewScheduleScreen.dart';
import 'package:gava/Firebase/FirebaseDBHelper.dart';

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  ScrollController _scrollController = ScrollController();
  List<String> _sortedDates = [];

  List<DragAndDropList> _dragAndDropLists = [];
  Map<String, List<ScheduleData>> scheduleDataMap = {};
  double itemHeight = 80.0;

  GlobalKey _calendarKey = GlobalKey();


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchSchedulesAndPrepareData();
    });
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_sortedDates.isEmpty || _dragAndDropLists.isEmpty) {
      return;
    }

    double cumulativeHeight = 0.0;
    int listIndex = 0;

    for (var list in _dragAndDropLists) {
      double listHeight = itemHeight * (list.children?.length ?? 0);
      if (_scrollController.offset <= cumulativeHeight + listHeight) {
        break;
      }
      cumulativeHeight += listHeight;
      listIndex++;
    }

    // Use listIndex to get the date from _sortedDates
    if (listIndex < _sortedDates.length) {
      String visibleDateKey = _sortedDates[listIndex];
      DateTime visibleDate = DateFormat('yyyy-MM-dd').parse(visibleDateKey);
      if (!isSameDay(_selectedDate, visibleDate)) {
        setState(() {
          _selectedDate = visibleDate;
        });
      }
    }
  }

  String _getDateKeyForIndex(int index) {
    if (_sortedDates.isEmpty) {
      return ''; // Return an empty string or handle it appropriately if the list is empty.
    }

    int runningIndex = 0;
    for (String dateKey in _sortedDates) {
      int itemCount = scheduleDataMap[dateKey]?.length ?? 0;
      runningIndex += itemCount;
      if (index < runningIndex) {
        return dateKey;
      }
    }
    return _sortedDates.last; // Only access last if the list is not empty.
  }


  int? _getIndexForDateKey(String dateKey) {
    int runningIndex = 0;
    for (String key in _sortedDates) {
      if (key == dateKey) {
        return runningIndex;
      }
      runningIndex += scheduleDataMap[key]?.length ?? 0;
    }
    return null; // Return null if the date is not found.
  }

  void fetchSchedulesAndPrepareData() async {
    try {
      scheduleDataMap = await FirebaseDBHelper().fetchAndGroupUserSchedules();

      // Clear the existing _sortedDates and populate it with new dates from scheduleDataMap.
      _sortedDates.clear();
      _sortedDates.addAll(scheduleDataMap.keys);
      // Sort the dates in ascending order.
      _sortedDates.sort((a, b) => DateFormat('yyyy-MM-dd').parse(a).compareTo(DateFormat('yyyy-MM-dd').parse(b)));

      _createDragAndDropLists();
    } catch (e) {
      print('Error fetching schedules: $e');
    }
  }



  void _createDragAndDropLists() {
    _dragAndDropLists.clear();
    scheduleDataMap.forEach((date, schedules) {
      List<DragAndDropItem> dragAndDropItems = schedules.map((schedule) {
        return DragAndDropItem(
          child: GestureDetector(
            onTap: (){
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NewScheduleScreen(scheduleData: schedule),
                ),
              );
            },
            child: ListTile(
              title: Text(schedule.title, style: TextStyle(color: Colors.white)),
              trailing: Icon(Icons.drag_handle, color: Colors.grey),
            ),
          ),
        );
      }).toList();

      _dragAndDropLists.add(
        DragAndDropList(
          header: Container(
            width: MediaQuery.of(context).size.width,
            padding: EdgeInsets.only(top: 20, right: 20, left: 20),
            decoration: BoxDecoration(
              color: SECONDARY_COLOR,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
            ),
            child: Text(
              date,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          children: dragAndDropItems,
        ),
      );
    });

    setState(() {});
  }

  void _onItemReorder(int oldItemIndex, int oldListIndex, int newItemIndex, int newListIndex) {
    setState(() {
      String oldDateKey = scheduleDataMap.keys.elementAt(oldListIndex);
      String newDateKey = scheduleDataMap.keys.elementAt(newListIndex);

      ScheduleData? movedSchedule = scheduleDataMap[oldDateKey]?.removeAt(oldItemIndex);

      if (movedSchedule != null) {
        // Check if the item is being moved within the same list
        if (oldListIndex == newListIndex) {
          scheduleDataMap[newDateKey]?.insert(newItemIndex, movedSchedule);
        } else {
          // Adjust newItemIndex for moving to a different list
          newItemIndex = newItemIndex > (scheduleDataMap[newDateKey]?.length ?? 0) ? (scheduleDataMap[newDateKey]?.length ?? 0) : newItemIndex;
          scheduleDataMap[newDateKey]?.insert(newItemIndex, movedSchedule);

          // Update Firestore
          FirebaseDBHelper().updateScheduleDate(movedSchedule.docId, newDateKey);
        }
        fetchSchedulesAndPrepareData();
      }
    });
  }



  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      String oldDateKey = getDateKeyForGlobalIndex(oldIndex);
      String newDateKey = getDateKeyForGlobalIndex(newIndex);
      int localOldIndex = getLocalIndexForGlobalIndex(oldIndex, oldDateKey);
      int localNewIndex = getLocalIndexForGlobalIndex(newIndex, newDateKey);

      ScheduleData? movedSchedule = scheduleDataMap[oldDateKey]?.removeAt(localOldIndex);
      if (movedSchedule != null) {
        scheduleDataMap[newDateKey]?.insert(localNewIndex, movedSchedule);
        FirebaseDBHelper().updateScheduleDate(movedSchedule.docId, newDateKey);
        fetchSchedulesAndPrepareData();

      }
    });
  }


  String getDateKeyForGlobalIndex(int index) {
    int runningIndex = 0;
    for (String dateKey in scheduleDataMap.keys) {
      int taskListLength = scheduleDataMap[dateKey]?.length ?? 0;
      runningIndex += taskListLength;
      if (index < runningIndex) {
        return dateKey;
      }
    }
    return scheduleDataMap.keys.last; // Fallback
  }

  int getLocalIndexForGlobalIndex(int globalIndex, String dateKey) {
    int runningIndex = 0;
    for (String key in scheduleDataMap.keys) {
      if (key == dateKey) {
        return globalIndex - runningIndex;
      }
      runningIndex += scheduleDataMap[key]?.length ?? 0;
    }
    return 0; // Should not reach here
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 23),
                child: Text('캘린더', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w600)),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 23, vertical: 6),
                child: Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: PRIMARY_COLOR
                  ),
                  child: IconButton(
                    icon: Icon(Icons.add, color: Colors.white,),
                    iconSize: 20,
                    onPressed: () async {
                      bool? result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => NewScheduleScreen()),
                      );

                      if (result == true) {
                        fetchSchedulesAndPrepareData();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 0),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                  color: SECONDARY_COLOR
              ),
              height: 150,
              child: TableCalendar(
                key: _calendarKey,
                daysOfWeekStyle: DaysOfWeekStyle( weekdayStyle: TextStyle(color: Colors.grey), weekendStyle: TextStyle(color: Colors.grey)),
                headerStyle: HeaderStyle(
                    titleCentered: true,
                    titleTextStyle: TextStyle(color: Colors.grey, fontSize: 20),
                    leftChevronIcon: Icon(Icons.chevron_left, color: Colors.grey,),
                    rightChevronIcon: Icon(Icons.chevron_right, color: Colors.grey,),
                    formatButtonVisible: false
                ),
                firstDay: DateTime.utc(2010, 10, 16),
                lastDay: DateTime.utc(2030, 3, 14),
                focusedDay: _selectedDate,
                locale: 'ko_KR',
                calendarFormat: CalendarFormat.week,
                selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDate = selectedDay;
                    // Scroll to the corresponding date in the list.
                    int? index = _getIndexForDateKey(DateFormat('yyyy-MM-dd').format(selectedDay));
                    if (index != null) {
                      _scrollController.animateTo(
                        index * itemHeight, // Adjust this based on your item heights.
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  });
                },
                calendarStyle: CalendarStyle(
                  isTodayHighlighted: false,
                  todayDecoration: BoxDecoration(
                    color: PRIMARY_COLOR,
                    borderRadius: BorderRadius.circular(23),
                  ),
                  todayTextStyle: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                  tablePadding: EdgeInsets.symmetric(horizontal: 20),
                  defaultTextStyle: TextStyle(color: Colors.grey, fontSize: 15),
                  // rowDecoration: BoxDecoration(color: TERTIARY_COLOR,borderRadius: BorderRadius.circular(23)),
                  cellPadding: EdgeInsets.symmetric(horizontal: 5,vertical: 2),
                  selectedDecoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: PRIMARY_COLOR,
                    // borderRadius: BorderRadius.circular(12),
                  ),
                  selectedTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          _dragAndDropLists.isEmpty
              ? Padding(
              padding: const EdgeInsets.all(50.0),
              child: Text("+ 버튼을 눌러\n\n새로운 일정을 만들어 보세요",
                  style: TextStyle(color: Colors.white70, fontSize: 18,),
              textAlign: TextAlign.center,)
          )
              : Expanded(
            child: DragAndDropLists(
              scrollController: _scrollController,
              children: _dragAndDropLists,
              onItemReorder: _onItemReorder,
              onListReorder: (oldListIndex, newListIndex) {
                setState(() {
                  var movedList = _dragAndDropLists.removeAt(oldListIndex);
                  _dragAndDropLists.insert(newListIndex, movedList);
                });
              },
              listPadding: EdgeInsets.symmetric(horizontal: 20,vertical: 8),
              listInnerDecoration: BoxDecoration(
                color: SECONDARY_COLOR,
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24),bottomRight:  Radius.circular(24)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(String dateKey, List<ScheduleData> taskList) {
    return Card(
      key: ValueKey(dateKey), // Unique key for ReorderableListView
      margin: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(23),
      ),
      color: SECONDARY_COLOR,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              dateKey,
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            Divider(color: Colors.grey),
            ReorderableListView.builder(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: taskList.length,
              itemBuilder: (context, taskIndex) {
                final taskItem = taskList[taskIndex];
                // Check if ScheduleData has a date property; if not, use a different key
                return ListTile(
                  key: ValueKey('${taskItem.startDate}_${taskItem.title}_${taskIndex}'),
                  title: Text(
                    taskItem.title,
                    style: TextStyle(color: Colors.white70),
                  ),
                  trailing: ReorderableDragStartListener(
                    index: taskIndex,
                    child: Icon(Icons.menu, color: Colors.grey),
                  ),
                );
              },
              onReorder: (oldIndex, newIndex) {
                _onReorder(oldIndex, newIndex);
              },
            ),
          ],
        ),
      ),
    );
  }

}
