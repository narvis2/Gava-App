import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:line_icons/line_icons.dart';

import 'package:gava/DoList/DoListMainScreen.dart';
import 'package:gava/calendar/CalendarScreen.dart';
import 'package:gava/Profile/Login/LoginScreen.dart';
import 'package:gava/Profile/ProfileScreen.dart';
import 'package:gava/Memo/MemoScreen.dart';

import 'package:gava/Firebase/FirebaseLoginHelper.dart';

import 'configure/configure.dart';

class TabbarScreen extends StatefulWidget {
  final String? email;
  final String? password;

  TabbarScreen({this.email, this.password});

  @override
  _TabbarScreenState createState() => _TabbarScreenState();
}

class _TabbarScreenState extends State<TabbarScreen> {
  int _selectedIndex = 0;

  final _pages = [
    DoListMainScreen(),
    // MemoScreen(),
    CalendarScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.email != null && widget.password != null)
    _login();
  }

  Future<void> _login() async {
    FirebaseLoginHelper().emailSignIn(widget.email!, widget.password!, context);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color(0xFF000000), // This sets the background color of the app
        body: _pages[_selectedIndex],
      bottomNavigationBar: Padding(
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 30),
        child: Container(
          // height: 85,
          decoration: BoxDecoration(
            color: Color(0xff191919), // Color for the tab bar
            borderRadius: BorderRadius.all(Radius.circular(40),),
            boxShadow: [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 10,
                spreadRadius: 1,
                offset: Offset(0, -1), // changes position of shadow
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8),
              child: GNav(
                padding: EdgeInsets.symmetric(horizontal: 20,vertical: 15),
                selectedIndex: _selectedIndex,
                backgroundColor: Color(0xff191919),
                onTabChange: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                tabs: [
                  GButton(
                    backgroundColor: PRIMARY_COLOR,
                    iconActiveColor: Colors.white,
                    iconColor: Colors.white54,
                    textColor: Colors.white,
                    icon: Icons.home_filled,
                    text: ' Home',
                    textStyle: TextStyle(fontSize: 18,color: Colors.white),
                  ),
                  // GButton(
                  //   backgroundColor: PRIMARY_COLOR,
                  //   iconActiveColor: Colors.white,
                  //   iconColor: Colors.white54,
                  //   textColor: Colors.white,
                  //   icon: Icons.edit_document,
                  //   text: ' Memo',
                  //   textStyle: TextStyle(fontSize: 18,color: Colors.white),
                  // ),
                  GButton(
                    backgroundColor: PRIMARY_COLOR,
                    iconActiveColor: Colors.white,
                    iconColor: Colors.white54,
                    textColor: Colors.white,
                    icon: Icons.calendar_today_rounded,
                    text: ' Week',
                    textStyle: TextStyle(fontSize: 18,color: Colors.white),
                  ),
                  GButton(
                    backgroundColor: PRIMARY_COLOR,
                    icon: Icons.person,
                    iconColor: Colors.white54,
                    textColor: Colors.white,
                    iconActiveColor: Colors.white,
                    text: ' My',
                    textStyle: TextStyle(fontSize: 18,color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      )
    );
  }
}