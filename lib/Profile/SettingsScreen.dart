import 'package:flutter/material.dart';
import 'package:gava/configure/configure.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:gava/configure/CustomAlertDialog.dart';
import 'package:gava/Firebase/FirebaseLoginHelper.dart';
import 'package:gava/Profile/Login/LoginScreen.dart';
import 'package:gava/configure/WebViewScreen.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String appVersion = "";

  @override
  void initState() {
    super.initState();
    _getAppVersion();
  }

  Future<void> _getAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      appVersion = packageInfo.version;
    });
  }

  void _showConfirmDialog(String title, String content, String buttonText1, String buttonText2, String action) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomAlertDialog(
          title: title,
          content: content,
          buttonText1: buttonText1,
          buttonText2: buttonText2,
          onConfirm: () async{
            if(action == "Logout"){
              FirebaseLoginHelper().signOutUser();
            } else {
              FirebaseLoginHelper().deleteUserAccount();
            }
            Navigator.of(context).pop(); // Close the dialog
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
                  (Route<dynamic> route) => false, // This removes all previous routes
            );

            },
          onCancel: () {
            Navigator.of(context).pop(); // Close the dialog
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('설정', style: TextStyle(fontSize: 28),),
        backgroundColor: Colors.transparent,// 'Settings'
        centerTitle: true,
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 23, vertical: 50),
        child: ListView(
          children: <Widget>[
            Container(
              padding: EdgeInsets.only(left: 10, top: 5, bottom: 5),
              margin: EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: SECONDARY_COLOR,
                borderRadius: BorderRadius.circular(24)
              ),
              child: ListTile(
                leading: Text('앱 버전 : $appVersion',style: TextStyle(color: Colors.white, fontSize: 16), ), // 'App Version'
                // trailing: Container(
                //   padding: EdgeInsets.only(right: 7, left: 7),
                //   decoration: BoxDecoration(
                //       color: Color(0xff2B2B2B),
                //       borderRadius: BorderRadius.circular(32)
                //   ),
                //   child: TextButton(
                //     onPressed: (){},
                //     child: Text('업데이트', style: TextStyle(color: Colors.white.withOpacity(0.9)),),
                //   ),
                // ),
              ),
            ),
            Container(
              padding: EdgeInsets.only(left: 10, top: 5, bottom: 5),
              margin: EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                  color: SECONDARY_COLOR,
                  borderRadius: BorderRadius.circular(24)
              ),
              child: ListTile(
                leading: Text('오픈소스 라이센스' , style: TextStyle(color: Colors.white),), // 'Open Source License'
                trailing: Icon(Icons.chevron_right,color: Colors.white,),
                onTap: () {
                  showLicensePage(
                      context: context,
                      applicationName: 'GAVA',
                      applicationVersion: '$appVersion',
                      applicationLegalese: '© 2023 엔프랩'
                  );
                },
              ),
            ),
            Container(
              padding: EdgeInsets.only(left: 10, top: 5, bottom: 5),
              margin: EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                  color: SECONDARY_COLOR,
                  borderRadius: BorderRadius.circular(24)
              ),
              child: ListTile(
                leading: Text('이용약관 및 개인정보 처리방침' , style: TextStyle(color: Colors.white),), // 'Terms and Privacy Policy'
                trailing: Icon(Icons.chevron_right,color: Colors.white,),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return WebViewScreen(
                          url: 'https://laser-platypus-8f8.notion.site/GAVA-6f5e49c67ef345f2973d92a0598c8f12?pvs=4',
                          title: '이용약관',
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: EdgeInsets.only(left: 10, top: 5, bottom: 5),
              margin: EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                  color: SECONDARY_COLOR,
                  borderRadius: BorderRadius.circular(24)
              ),
              child: ListTile(
                title: Text('로그아웃' , style: TextStyle(color: Colors.grey),), // 'Logout'
                onTap: (){
                  _showConfirmDialog('로그아웃' , '정말 로그아웃 하시겠어요?' , '네,로그아웃 할래요' , '아니요', 'Logout');
                }
              ),
            ),
            ListTile(
              title: Text('회원탈퇴', style: TextStyle(color: Colors.grey),), // 'Delete Account'
              onTap:(){
                _showConfirmDialog('회원탈퇴' , '정말 계정을 삭제하시겠어요?', '네, 삭제할래요', '아니요', 'DeleteAccount');
              }
            ),
          ],
        ),
      ),
    );
  }

}
