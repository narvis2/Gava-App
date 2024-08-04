import 'package:flutter/material.dart';
import 'package:gava/configure/configure.dart';
import 'package:gava/Firebase/FirebaseLoginHelper.dart';
import 'package:gava/Firebase/FirebaseDBHelper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gava/Profile/Login/LoginScreen.dart';
import 'package:gava/Profile/TotalDoneListScreen.dart';
import 'package:random_nickname/random_nickname.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:flutter/widgets.dart';
import 'dart:ui';
import 'package:gava/Profile/SettingsScreen.dart';
import 'package:gava/DoList/CreateDoListScreen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseLoginHelper _firebaseLoginHelper = FirebaseLoginHelper();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _workController = TextEditingController();

  bool _isEditing = false;

  OverlayEntry? _overlayEntry;
  Map<int, GlobalKey> itemKeys = {};
  bool isOverlayShown = false;
  List<DoList> _doneDoLists = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    itemKeys.clear();
    _usernameController.dispose();
    _workController.dispose();

    super.dispose();
  }

  void _loadData() async {
    var doneDoLists = await FirebaseDBHelper().fetchDoneDoLists();
    setState(() {
      _doneDoLists = doneDoLists;
    });
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
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 23.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              FutureBuilder<UserProfile?>(
                future: FirebaseDBHelper().fetchUserProfile(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }

                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }

                  UserProfile? userProfile = snapshot.data;
                  if (userProfile != null) {
                    Future.delayed(Duration.zero, () {
                      _usernameController.text = userProfile.nickname;
                      _workController.text = userProfile.quote ??
                          ''; // Assuming quote is an optional field
                    });
                    return buildUserProfileSection(userProfile);
                  } else {
                    return Container();
                  }
                },
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 0, vertical: 15),
                child: Divider(
                  color: Colors.white.withOpacity(0.6),
                  height: 1,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 0, vertical: 15),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '하루 평균계획',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                              color: Colors.grey),
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        Container(
                          width: 100,
                          height: 50,
                          child: FutureBuilder<double>(
                            future: FirebaseDBHelper()
                                .calculateAverageTotalDoListItems(),
                            builder: (context, snapshot) {
                              print(
                                  "FutureBuilder state: ${snapshot.connectionState}");
                              print("Snapshot data: ${snapshot.data}");
                              print("Snapshot error: ${snapshot.error}");
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return CircularProgressIndicator(); // Show loading indicator while waiting
                              } else if (snapshot.hasError) {
                                return Text(
                                    "Error: ${snapshot.error}"); // Show error if any
                              } else {
                                print('fetched');
                                return Text(
                                  "${snapshot.data!.toStringAsFixed(0)}개",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600),
                                ); // Show the result
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: 20,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '하루 평균성공',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                              color: Colors.grey),
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        Container(
                          width: 100,
                          height: 50,
                          child: FutureBuilder<double>(
                            future: FirebaseDBHelper()
                                .calculateAverageDoneDoListItems(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return CircularProgressIndicator(); // Show loading indicator while waiting
                              } else if (snapshot.hasError) {
                                return Text(
                                    "Error: ${snapshot.error}"); // Show error if any
                              } else {
                                print("${snapshot.data}개");
                                return Text(
                                  "${snapshot.data!.toStringAsFixed(0)}개",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600),
                                ); // Show the result
                              }
                            },
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Container(
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24)),
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 10, top: 20),
                        child: Text(
                          '오늘의 다짐',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 15,
                          ),
                        ),
                      ),
                      TextField(
                        controller: _workController,
                        decoration: InputDecoration(
                          hintText: '오늘의 다짐을 입력하세요.',
                          hintStyle: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.normal),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600),
                        readOnly: !_isEditing,
                      ),
                    ],
                  )),
              SizedBox(height: 30),
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '완료한 계획',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton(
                        child: Text(
                          '전체보기',
                          style: TextStyle(color: TONED_DOWN_TEXTCOLOR),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => TotalDoneListScreen()),
                          );
                        },
                      )
                    ],
                  )),
              Container(
                height: 120, // Set a fixed height for the horizontal list
                child: FutureBuilder<List<DoList>>(
                  future: FirebaseDBHelper().fetchDoneDoLists(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      // If the list is empty, show the placeholder text
                      return Center(
                          child: Text('완료된 계획이 없어요',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 16)));
                    } else {
                      List<DoList> doneDoLists = snapshot.data!
                          .sublist(0, min(5, snapshot.data!.length));
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: doneDoLists.length,
                        itemBuilder: (context, index) {
                          return buildHorizontalListItem(
                              doneDoLists[index], index);
                        },
                      );
                    }
                  },
                ),
              ),
              SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SettingsScreen()),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                      color: SECONDARY_COLOR,
                      borderRadius: BorderRadius.circular(23)),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Image.asset(
                              'assets/setting.png',
                              width: 30,
                              height: 30,
                            ),
                            Text(
                              '      옵션',
                              style: TextStyle(color: Colors.white),
                            )
                          ],
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: Colors.white,
                        )
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget buildHorizontalListItem(DoList doList, int index) {
    String formattedDate =
        DateFormat('yy년 MM월 dd일').format(DateTime.parse(doList.startDate));
    var key = GlobalKey(debugLabel: 'DoneDoListKey_$index');

    return GestureDetector(
      key: key,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateDoListScreen(doList: doList),
          ),
        );
      },
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
        width: 168,
        height: 98,
        margin: EdgeInsets.all(8.0),
        padding: EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          color: Color(0xff191919),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  formattedDate,
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15),
                  textAlign: TextAlign.start,
                ),
                SizedBox(height: 8),
                Text(
                  doList.title,
                  style: TextStyle(color: Color(0xff767676), fontSize: 15),
                  textAlign: TextAlign.start,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildUserProfileSection(UserProfile userProfile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50.0,
              height: 50.0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(17.0),
              ),
              child: Image.asset('assets/${userProfile.profileImg}'),
            ),
            SizedBox(
              width: 15,
            ),
            SizedBox(
              height: 50,
              width: 180,
              child: TextField(
                controller: _usernameController,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w600),
                readOnly: !_isEditing,
              ),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
              color: _isEditing ? PRIMARY_COLOR : Color(0xff191919),
              borderRadius: BorderRadius.circular(12)),
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: TextButton(
            child: Text(
              _isEditing ? '완료' : '프로필편집',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () {
              if (_isEditing) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  // Call the update method after the build is complete
                  FirebaseDBHelper().updateUserProfile(
                      _usernameController.text, _workController.text);
                });
              }
              setState(() {
                _isEditing = !_isEditing;
              });
            },
          ),
        )
      ],
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
}
