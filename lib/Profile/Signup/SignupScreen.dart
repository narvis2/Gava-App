import 'package:flutter/material.dart';
import 'package:gava/configure/configure.dart';
import 'package:gava/Firebase/FirebaseLoginHelper.dart';
import 'package:gava/Firebase/FirebaseDBHelper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gava/Profile/Login/LoginScreen.dart';
import 'package:random_nickname/random_nickname.dart';
import 'package:gava/configure/WebViewScreen.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController = TextEditingController();
  final FirebaseLoginHelper _firebaseLoginHelper = FirebaseLoginHelper();
  String _signUpErrorMessage = '';
  String _savedEmail = '';

  bool _termsAccepted = false;

  bool _isEmailSent = false;
  String _verificationEmailSentMessage = '';

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();

    super.dispose();
  }


  Future<void> _trySignUp() async {
    String email = _idController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _passwordConfirmController.text.trim();

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        _signUpErrorMessage = 'Fields cannot be empty.';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _signUpErrorMessage = 'Passwords do not match.';
      });
      return;
    }

    try {
      await _firebaseLoginHelper.emailSignUp(email, password);
      setState(() {
        _isEmailSent = true;
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'weak-password') {
          _signUpErrorMessage = '비밀번호가 너무 약합니다.';
        } else if (e.code == 'email-already-in-use') {
          _signUpErrorMessage = '이미 가입된 이메일입니다.';
        } else {
          _signUpErrorMessage = e.message ?? 'An unknown error occurred.';
        }
      });
    } catch (e) {
      setState(() {
        _signUpErrorMessage = e.toString();
      });
    }
  }

  Future<void> _completeVerification() async {
    var user = FirebaseAuth.instance.currentUser;
    var nickname = randomNickname([korAdjectiveEmotion, korNounAnimal]);

    if (user != null) {
      await user.reload();
      user = FirebaseAuth.instance.currentUser;

      if (user!.emailVerified) {
        await FirebaseDBHelper().createUserProfile(user.uid, _idController.text, 'chick1.png', nickname);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      } else {
        // Email is not verified, show an error or a reminder
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이메일 인증이 완료되지 않았어요. 등록하신 이메일을 확인해주세요.')),
        );
      }
    } else {
      // No user found, handle appropriately
    }
  }



  @override
  Widget build(BuildContext context) {

    if (_signUpErrorMessage.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_signUpErrorMessage)),
        );
      });
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 23.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              '회원가입을',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w400,
              ),
            ),
            Text(
              '시작해볼까요?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 40),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10,vertical: 10),
              child: Text(
                '아이디',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24)
              ),
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              child: TextField(
                controller: _idController,
                decoration: InputDecoration(
                  hintText: '이메일을 입력하세요.',
                  hintStyle: TextStyle(color: TONED_DOWN_TEXTCOLOR, fontWeight: FontWeight.normal),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: TextStyle(color: Colors.white,fontWeight: FontWeight.w600),
              ),
            ),
            SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10,vertical: 10),
              child: Text(
                '비밀번호',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(23)
              ),
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: [
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: '비밀번호를 입력하세요.',
                      hintStyle: TextStyle(color: TONED_DOWN_TEXTCOLOR, fontWeight: FontWeight.normal),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Divider(color: Colors.grey,),
                  ),
                  TextField(
                    controller: _passwordConfirmController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: '비밀번호를 다시 입력하세요.',
                      hintStyle: TextStyle(color: TONED_DOWN_TEXTCOLOR),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              )
            ),
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10,vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '이용약관',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
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
                          child: Text('약관 전체보기', style: TextStyle(color: Colors.grey),),
                      ),
                    ],
                  ),
                  SizedBox(height: 10,),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 5),
                    decoration: BoxDecoration(
                      color: SECONDARY_COLOR,
                      borderRadius: BorderRadius.circular(20)
                    ),
                    child:  Theme(
                      data: ThemeData(unselectedWidgetColor: Colors.grey),
                      child: CheckboxListTile(
                        title: Text(
                          '이용약관에 동의합니다',
                          style: TextStyle(color: Colors.white),
                        ),
                        value: _termsAccepted,
                        onChanged: (newValue) {
                          setState(() {
                            _termsAccepted = newValue!;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.trailing, // Position the checkbox at the end
                        activeColor: PRIMARY_COLOR,
                        checkColor: Colors.white,
                        contentPadding: EdgeInsets.zero,
                      ),
                    )

                  )
                ],
              )
            ),
            SizedBox(height: 20),
            if (_isEmailSent)
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Text(
                  '입력하신 이메일로 인증 이메일을 보냈어요!\n링크를 클릭하여 인증을 완료해주세요.',
                  style: TextStyle(color: PRIMARY_COLOR, fontSize: 16,),
                ),
              ),
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      primary: PRIMARY_COLOR, // Background color
                      onPrimary: Colors.white, // Text color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                      minimumSize: Size(double.infinity, 50),
                    ),
                    onPressed: _termsAccepted
                        ? (_isEmailSent ? _completeVerification : _trySignUp)
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 26.0),
                      child: Text(_isEmailSent ? '인증완료' : '이메일 인증',style: TextStyle(fontSize: 18),),
                    ),
                  ),

                ),
              ),
            )
            // Add other widgets for further sign-up steps
          ],
        ),
      ),
    );
  }
}
