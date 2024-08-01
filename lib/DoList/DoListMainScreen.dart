import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:gava/Firebase/FirebaseDBHelper.dart';
import 'package:gava/configure/configure.dart';
import 'dart:math';
import 'package:flutter/scheduler.dart';
import 'package:gava/configure/CustomAlertDialog.dart';
import 'package:gava/DoList/CreateDoListScreen.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:math';


class DoListMainScreen extends StatefulWidget {
  @override
  _DoListMainScreenState createState() => _DoListMainScreenState();
}

class _DoListMainScreenState extends State<DoListMainScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController(viewportFraction: 1);
  DateTime _selectedDate = DateTime.now();
  late AnimationController _animationController; // Declare as late
  double _todoListHeight = 0;
  List<List<List<DoList>>> _pages = [];
  static const double _itemHeight = 100.0;
  static const double _maxPageHeight = 300.0;
  int _currentPage = 0;
  List<ScheduleData> _currentSchedules = [];

  ValueNotifier<double> pageViewHeightNotifier = ValueNotifier(0);
  StreamSubscription? _subscription;


  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _subscription = FirebaseDBHelper().getUserDoLists().listen((doLists) {
        if(mounted){
          setState(() {
            _pages = _splitIntoPages(doLists, MediaQuery.of(context).size.width - 40);
          });


        }
      });
    });
  }

  List<List<List<DoList>>> _splitIntoPages(List<DoList> doLists, double pageWidth) {
    print("doLists length: ${doLists.length}");  // Debugging

    List<List<List<DoList>>> pages = [];
    List<List<DoList>> currentRows = [];
    List<DoList> currentRow = [];
    double currentRowWidth = 0.0;
    double currentPageHeight = 0.0;

    for (var doList in doLists) {
      double itemWidth = _getItemWidth(doList.importance, pageWidth);
      if (currentRowWidth + itemWidth > pageWidth) {
        currentRows.add(List.from(currentRow));
        currentPageHeight += _itemHeight;
        currentRow.clear();
        currentRowWidth = 0.0;
      }

      currentRow.add(doList);
      currentRowWidth += itemWidth;

      if (currentPageHeight + _itemHeight > _maxPageHeight) {
        pages.add(List.from(currentRows));
        currentRows.clear();
        currentPageHeight = 0.0;
      }

      print("Processing DoList: ${doList.title}, itemWidth: $itemWidth, currentRowWidth: $currentRowWidth, currentPageHeight: $currentPageHeight");
    }

    // Add any remaining items
    if (currentRow.isNotEmpty) {
      currentRows.add(List.from(currentRow));
    }
    if (currentRows.isNotEmpty) {
      pages.add(List.from(currentRows));
    }

    print("Number of pages: ${pages.length}");  // Debugging
    return pages;
  }




  double _getItemWidth(int importance, double pageWidth) {
    // Return the item width based on its importance.
    switch (importance) {
      case 3:
        return pageWidth;
      case 2:
        return pageWidth * 2 / 3;
      case 1:
        return pageWidth / 3;
      default:
        return pageWidth / 3;
    }
  }


  double calculatePageHeight(List<List<DoList>> pageContent) {
    // Implement logic to calculate height based on the content of pageContent
    // This might involve checking the number of items and their individual heights
    // For simplicity, let's assume each item in the page has a fixed height
    double totalHeight = 0;
    for (var row in pageContent) {
      totalHeight += _itemHeight; // Assuming each row has a height of _itemHeight
    }
    return totalHeight;
  }


  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _subscription?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF000000),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Container(
                padding: EdgeInsets.all(23),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget> [
                    FutureBuilder<UserProfile?>(
                      future: FirebaseDBHelper().fetchUserProfile(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          // Display loading indicator while waiting for the data
                          return CircularProgressIndicator();
                        }

                        if (snapshot.hasError) {
                          // Handle error state
                          return Text('Error: ${snapshot.error}');
                        }

                        UserProfile? userProfile = snapshot.data;

                        return userProfile != null ? buildUserProfileSection(userProfile) : Container(); // Replace with your user profile section
                      },
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        color: Colors.black, // Background color for the indicator container
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,

                          children: [
                            IconButton(
                              icon: Icon(Icons.chevron_left, color: Colors.white),
                              onPressed: () {
                                // Go to the previous page
                                if (_pageController.page!.round() != 0) {
                                  _pageController.previousPage(
                                    duration: Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                }
                              },
                            ),
                            // Page indicator
                            Text(
                              '${_currentPage + 1} / ${max(1, _pages.length)}',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                            IconButton(
                              icon: Icon(Icons.chevron_right, color: Colors.white),
                              onPressed: () {
                                // Go to the next page
                                if (_pageController.page!.round() != _pages.length - 1) {
                                  _pageController.nextPage(
                                    duration: Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: PRIMARY_COLOR,
                            borderRadius: BorderRadius.circular(12)
                          ),
                          child: TextButton(
                            child: Icon(Icons.add, color: Colors.white),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => CreateDoListScreen()),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  LayoutBuilder(
                      builder: (context,constraints) {
                        return ValueListenableBuilder(
                            valueListenable: pageViewHeightNotifier,
                            builder: (context, value, child) {
                            return Column(
                              children: [
                                _pages.length == 0
                                    ? Padding(
                                    padding: const EdgeInsets.all(50.0),
                                    child: Text("+ 버튼을 눌러 새로운 계획을 만들어 보세요",
                                        style: TextStyle(color: Colors.white70, fontSize: 18))
                                )
                                    : Container(
                                  height: value,
                                  child: PageView.builder(
                                    controller: _pageController,
                                    itemCount: _pages.length,
                                    onPageChanged: (index) {
                                      setState(() {
                                        _currentPage = index;
                                      });
                                    },
                                    itemBuilder: (context, index) {
                                      double calculatedHeight = calculatePageHeight(_pages[index]);
                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        if (pageViewHeightNotifier.value != calculatedHeight) {
                                          pageViewHeightNotifier.value = calculatedHeight;
                                        }
                                      });
                                      return _buildPage(_pages[index]);
                                    },
                                    physics: NeverScrollableScrollPhysics(),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(
                                      top: max(120, _todoListHeight + 20),
                                       left: 23,
                                      right: 23),
                                  child: AnimatedContainer(
                                    duration: Duration(milliseconds: 300), // Adjust the animation speed as needed
                                    margin: EdgeInsets.only(top: _todoListHeight),
                                    decoration: BoxDecoration(
                                      color: Color(0xFF191919), // HEX color
                                      borderRadius: BorderRadius.circular(32.0), // Border radius
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(30.0), // Inner padding for content
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            '다가오는 일정',
                                            style: TextStyle(color: Colors.white, fontSize: 18),
                                          ),
                                          SizedBox(height: 25), // Add some space between the text and the calendar
                                          TableCalendar(
                                            headerVisible: false,
                                            calendarStyle: CalendarStyle(
                                              isTodayHighlighted: false,
                                              todayTextStyle: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                                              defaultTextStyle: TextStyle(color: Colors.grey, fontSize: 15),
                                              selectedDecoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: PRIMARY_COLOR,
                                                // borderRadius: BorderRadius.circular(12),
                                              ),
                                              selectedTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                            ),
                                            focusedDay: _selectedDate,
                                            firstDay: DateTime.utc(2010, 10, 16),
                                            lastDay: DateTime.utc(2030, 3, 14),
                                            calendarFormat: CalendarFormat.week,
                                            selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
                                            onDaySelected: (selectedDay, focusedDay) async {
                                              setState(() {
                                                _selectedDate = selectedDay;
                                              });
                                              _currentSchedules = await FirebaseDBHelper().fetchSchedulesForDate(DateFormat('yyyy-MM-dd').format(selectedDay));
                                              setState(() {}); // This will trigger a rebuild with the new schedules
                                            },
                                          ),
                                          ..._buildScheduleList(_currentSchedules),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                            }
                            );
                      }
                      ),
                ],
              ),
            ],
          ),
        ),
      ),
      // Add the bottom navigation bar here if needed
    );
  }

  Widget _buildPage(List<List<DoList>> pageRows) {
    List<DoList> pageItems = pageRows.expand((row) => row).toList();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        key: PageStorageKey('todoListKey'),
        children: pageRows.map((row) => _buildRow(row)).toList(),
      ),
    );
  }

  Widget _buildRow(List<DoList> rowItems) {
    return Row(
      children: rowItems.map((item) => _buildDoListItem(item)).toList(),
    );
  }

  Widget _buildDoListItem(DoList doList) {
    double screenWidth = MediaQuery.of(context).size.width-40;
    double cellWidth;
    switch (doList.importance) {
      case 3:
        cellWidth = screenWidth;
        break;
      case 2:
        cellWidth = screenWidth * 2 / 3;
        break;
      case 1:
      default:
        cellWidth = screenWidth * 1 / 3;
        break;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateDoListScreen(doList: doList),
          ),
        );
      },
      onLongPress: () async {
        final action = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return CustomAlertDialog(
              buttonText1: '네, 삭제할래요',
              buttonText2: '다음에',
              title: '삭제하기',
              content: '삭제된 할일은 프로필에서\n복구 가능해요!',
              onConfirm: () {
                FirebaseDBHelper().deleteDoList(doList.id);
                Navigator.of(context).pop();
                setState(() {});
              },
              onCancel: () {
                Navigator.of(context).pop();
              },
            );
          },
        );
      },
      child: Dismissible(
          key: Key(doList.id),
          background: Container(

            color: Colors.green, // Customize this color as needed
            alignment: Alignment.centerRight,
            child: Icon(Icons.check, color: Colors.white), // Customize this icon as needed
            padding: EdgeInsets.only(right: 20),
          ),
          direction: DismissDirection.startToEnd,
          onDismissed: (direction) async {
            await FirebaseDBHelper().changeDoListState(doList.id, true);
            // Refresh the UI
            setState(() {
              // Assuming _pages is the list of all DoLists
              // Find the page and row where this doList is located and remove it
              for (var page in _pages) {
                for (var row in page) {
                  row.removeWhere((item) => item.id == doList.id);
                }
                // Optionally, you could remove empty rows/pages here
                page.removeWhere((row) => row.isEmpty);
              }
              // _pages.removeWhere((page) => page.isEmpty);
            });
          },
          child: Container(
            width: cellWidth,
            height: 100,
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6.0),
            child: Material(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(24),
              child: doList.importance == 1
                  ? Center(
                child: Image.asset('assets/${doList.image}', height: 40, width: 40, fit: BoxFit.cover),
              )
                  : Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 25.0, right: 15),
                    child: Image.asset('assets/${doList.image}', height: 40, width: 40, fit: BoxFit.cover),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 25),
                    child: Text(
                      doList.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          )
      ),
    );
  }

  List<Widget> _buildScheduleList(List<ScheduleData> schedules) {
    // Group schedules by startTime
    var groupedSchedules = <String, List<ScheduleData>>{};
    for (var schedule in schedules) {
      (groupedSchedules[schedule.startTime] ??= []).add(schedule);
    }

    // Build a ListTile for each group
    return groupedSchedules.entries.map((entry) {
      var startTime = entry.key;
      var scheduleTitles = entry.value.map((s) => s.title).join('\n');
      return _currentSchedules.isEmpty
          ? Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text("🗓️에서 일정을 만들어보세요!",
              style: TextStyle(color: Colors.white70, fontSize: 18))
      )
          : Container(
        decoration: BoxDecoration(
            color: TERTIARY_COLOR,
            borderRadius: BorderRadius.circular(23)
        ),
        padding: EdgeInsets.symmetric(vertical: 15,horizontal: 10),
        margin: EdgeInsets.symmetric(vertical: 5),
        child: ListTile(
          title: Text(startTime.isNotEmpty ? startTime : scheduleTitles, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          subtitle: startTime.isNotEmpty ? Padding(
              padding: EdgeInsets.only(top: 5), // Added padding for spacing
              child: Text(scheduleTitles, style: TextStyle(color: Colors.grey))
          ) : null,
        ),
      );
    }).toList();
  }

  Widget buildUserProfileSection(UserProfile userProfile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 58.0, // Set the width to 58 pixels
          height: 58.0, // Set the height to 58 pixels
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17.0), // Rounded corners
          ),
          child: Image.asset('assets/${userProfile.profileImg}'),
        ),
        SizedBox(width: 10,),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.only(bottom: 6),
              child: Text(
                '${userProfile.nickname}님',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700,),
                textAlign: TextAlign.start,
              ),
            ),
            Text(
              '오늘도 응원할게요! 💪🏻',
              style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        )
      ],
    );
  }

}