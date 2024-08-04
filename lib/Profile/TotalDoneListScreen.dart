import 'package:flutter/material.dart';
import 'package:gava/configure/configure.dart';
import 'package:gava/Firebase/FirebaseDBHelper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:flutter/widgets.dart';

class TotalDoneListScreen extends StatefulWidget {
  @override
  _TotalDoneListScreenState createState() => _TotalDoneListScreenState();
}

class _TotalDoneListScreenState extends State<TotalDoneListScreen> {
  final TextEditingController _searchController = TextEditingController();
  OverlayEntry? _overlayEntry;
  Map<int, GlobalKey> itemKeys = {};
  bool isOverlayShown = false;
  List<DoList> _doneDoLists = [];

  @override
  void dispose() {
    _overlayEntry?.remove();
    _searchController.dispose();
    itemKeys.clear(); // Clear the keys when disposing of the state.
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    var doneDoLists = await FirebaseDBHelper().fetchDoneDoLists();
    setState(() {
      _doneDoLists = doneDoLists;
    });
  }

  Future<Map<String, List<DoList>>> fetchGroupedDoneDoLists() async {
    List<DoList> doneDoLists = await FirebaseDBHelper().fetchDoneDoLists();
    Map<String, List<DoList>> groupedDoLists = {};

    for (var doList in doneDoLists) {
      String monthYear =
          DateFormat('yy년 MM월').format(DateTime.parse(doList.startDate));
      if (!groupedDoLists.containsKey(monthYear)) {
        groupedDoLists[monthYear] = [];
      }
      groupedDoLists[monthYear]!.add(doList);
    }

    return groupedDoLists;
  }

  Future<List<DoList>> searchDoList() async {
    String searchText = _searchController.text;
    if (searchText.isEmpty) {
      return [];
    } else {
      return await FirebaseDBHelper()
          .searchDoListByTitleAndDoneState(searchText);
    }
  }

  void _showOverlay(BuildContext context, Offset offset, DoList doList) {
    print('Showing overlay for: ${doList.title}');

    // Safe removal of existing overlay entry
    if (isOverlayShown) {
      _overlayEntry?.remove();
      isOverlayShown = false;
    }

    // Create a new overlay entry
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: offset.dy,
        left: offset.dx,
        width: MediaQuery.of(context).size.width,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(Icons.refresh, '복구', () async {
                  await FirebaseDBHelper().changeDoListState(doList.id, false);
                  _overlayEntry?.remove();
                  isOverlayShown = false;
                  _loadData();
                }),
                SizedBox(
                  height: 10,
                ),
                _buildActionButton(Icons.delete, '삭제', () async {
                  await FirebaseDBHelper().deleteDoList(doList.id);
                  _overlayEntry?.remove();
                  isOverlayShown = false;
                  _loadData();
                }),
              ],
            ),
          ),
        ),
      ),
    );

    // Insert the overlay entry into the Overlay, if it's mounted
    Overlay.of(context)?.insert(_overlayEntry!);
    isOverlayShown = true;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (isOverlayShown) {
          _overlayEntry?.remove();
          isOverlayShown = false;
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            '완료한 계획',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w500),
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.only(top: 23.0, right: 23, left: 23),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                    color: SECONDARY_COLOR,
                    borderRadius: BorderRadius.circular(23)),
                padding: EdgeInsets.symmetric(horizontal: 30),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    icon: Icon(
                      Icons.search_rounded,
                      color: Colors.white,
                    ),
                    hintText: '날짜 또는 프로젝트 제목을 입력하세요.',
                    hintStyle: TextStyle(
                        color: TONED_DOWN_TEXTCOLOR,
                        fontWeight: FontWeight.normal),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(height: 30),
              Flexible(
                child: ValueListenableBuilder(
                  valueListenable: _searchController,
                  builder: (context, value, child) {
                    bool isSearchEmpty = _searchController.text.isEmpty;
                    return FutureBuilder<dynamic>(
                      future: isSearchEmpty
                          ? fetchGroupedDoneDoLists()
                          : searchDoList(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return Center(
                              child: Text('검색 결과가 없습니다',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 16)));
                        } else {
                          return isSearchEmpty
                              ? _buildGroupedDoList(snapshot.data)
                              : _buildSearchResults(snapshot.data);
                        }
                      },
                    );
                  },
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupedDoList(Map<String, List<DoList>> groupedDoLists) {
    List<Widget> children = [];
    groupedDoLists.forEach((monthYear, doLists) {
      children.add(
        Padding(
          padding: EdgeInsets.only(right: 23, top: 30, bottom: 10),
          child: Text(
            monthYear,
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
      );
      children.add(
        GridView.builder(
          shrinkWrap: true,
          physics:
              NeverScrollableScrollPhysics(), // to disable GridView's scrolling
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // number of cells in each row
            crossAxisSpacing: 10, // spacing between the cells horizontally
            mainAxisSpacing: 10, // spacing between the cells vertically
            childAspectRatio:
                (MediaQuery.of(context).size.width / 2 - 10 - 10) / 98,
          ),
          itemCount: doLists.length,
          itemBuilder: (context, index) {
            return buildGridItem(doLists[index], index);
          },
        ),
      );
    });
    return ListView(children: children);
  }

  Widget buildGridItem(DoList doList, int index) {
    var key = GlobalKey(debugLabel: 'DoListKey_$index');
    return GestureDetector(
      key: key,
      onLongPress: () {
        print('Long press detected for item $index');
        Future.delayed(Duration(milliseconds: 100), () {
          if (key.currentContext != null) {
            RenderBox box = key.currentContext!.findRenderObject() as RenderBox;
            if (box != null) {
              Offset position = box.localToGlobal(Offset.zero);
              Size size = box.size;
              print('Position: $position, Size: $size');
              _showOverlay(context, position, doList);
            } else {
              print('RenderBox is null for item $index');
            }
          } else {
            print('Current context is null for item $index');
          }
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xff191919),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                DateFormat('yy년 MM월 dd일')
                    .format(DateTime.parse(doList.startDate)),
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 10),
              Text(
                doList.title,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5), fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
      IconData icon, String label, VoidCallback onPressed) {
    return Container(
      height: 50,
      width: 100,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white),
        label: Text(label, style: TextStyle(color: Colors.white, fontSize: 15)),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: PRIMARY_COLOR,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(List<DoList> searchResults) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio:
            (MediaQuery.of(context).size.width / 2 - 10 - 10) / 98,
      ),
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        return buildGridItem(
            searchResults[index], index); // Use searchResults here
      },
    );
  }
}
