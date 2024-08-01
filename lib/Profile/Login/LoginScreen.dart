import 'package:flutter/material.dart';
import 'package:gava/configure/configure.dart';
import 'package:gava/Firebase/FirebaseLoginHelper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gava/TabbarScreen.dart';
import 'package:gava/Profile/Signup/SignupScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';


class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseLoginHelper _firebaseLoginHelper = FirebaseLoginHelper();
  String _signUpErrorMessage = '';
  String _savedEmail = '';

  String _idErrorMessage = '';
  String _passwordErrorMessage = '';

  bool _isEmailSent = false;
  String _verificationEmailSentMessage = '';

  bool _rememberMe = true;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();

    super.dispose();
  }


  Future<void> _trySignIn() async {
    String email = _idController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Fields cannot be empty.');
      return;
    }

    try {
      // Sign in with Firebase
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => TabbarScreen()),
      );

      if (_rememberMe) {
        await _saveCredentials(email, password);
      }
    } on FirebaseAuthException catch (e) {
      print("login error ${e.code}");
      if (e.code == 'user-not-found') {
        setState(() => _idErrorMessage = '아이디가 잘못되었습니다');
        _passwordErrorMessage = ''; // Clear password error
      } else if (e.code == 'wrong-password') {
        setState(() => _passwordErrorMessage = '비밀번호가 잘못되었습니다');
        _idErrorMessage = ''; // Clear ID error
      } else if (e.code == 'invalid-credential') {
        setState(() => _passwordErrorMessage = '비밀번호를 확인해주세요.');
        _idErrorMessage = '';
      } else {
        // Handle other errors
        _idErrorMessage = '';
        _passwordErrorMessage = '';
        _showSnackBar(e.message ?? 'An unknown error occurred.');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _saveCredentials(String email, String password) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', email);
    await prefs.setString('password', password);
  }



  Future<void> _resetPassword() async {
    String email = _idController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('비밀번호 재설정을 위해 아이디를 입력하세요.')),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('비밀번호 재설정을 위한 이메일을 보냈습니다.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이메일을 보내는데 실패했어요 : ${e.toString()}')),
      );
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
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 23.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Align(
              alignment: Alignment.center,
              child: Text(
                'GAVA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 40),
            Container(
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(23)
                ),
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10,vertical: 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '아이디',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 15,
                        ),
                      ),
                      TextField(
                        controller: _idController,
                        obscureText: false,
                        decoration: InputDecoration(
                          errorText: _idErrorMessage.isNotEmpty ? _idErrorMessage : null,
                          hintText: 'help@gava.com',
                          hintStyle: TextStyle(color: TONED_DOWN_TEXTCOLOR),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xff444444)),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: PRIMARY_COLOR),
                          ),
                          suffixIcon: _idController.text.isNotEmpty
                              ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.white),
                            onPressed: () {
                              setState(() {
                                _idController.clear();
                              });
                            },
                          )
                              : null,
                        ),
                        style: TextStyle(color: Colors.white),
                        onChanged: (value) {
                          setState(() {}); // Call setState to rebuild the widget with the clear icon
                        },
                      ),
                      SizedBox(height: 40,),
                      Text(
                        '비밀번호',
                        style: TextStyle(
                          color: TONED_DOWN_TEXTCOLOR,
                          fontSize: 15,
                        ),
                      ),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          errorText: _passwordErrorMessage.isNotEmpty ? _passwordErrorMessage : null,
                          hintText: 'password',
                          hintStyle: TextStyle(color: TONED_DOWN_TEXTCOLOR),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xff444444)),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: PRIMARY_COLOR),
                          ),
                          suffixIcon: _passwordController.text.isNotEmpty
                              ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.white),
                            onPressed: () {
                              setState(() {
                                _passwordController.clear();
                              });
                            },
                          )
                              : null,
                        ),
                        style: TextStyle(color: Colors.white),
                        onChanged: (value) {
                          setState(() {}); // Call setState to rebuild the widget with the clear icon
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (bool? value) async{
                                  setState(() {
                                    _rememberMe = value!;
                                  });
                                  if (_rememberMe) {
                                    await _saveCredentials(_idController.text, _passwordController.text);
                                  }
                                },
                                activeColor: PRIMARY_COLOR,
                                checkColor: Colors.white,
                                shape: CircleBorder(),
                                side: BorderSide(color: Colors.grey),
                              ),
                              Text(
                                '자동로그인',
                                style: TextStyle(color: Colors.grey, fontSize: 15),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              _resetPassword;
                            },
                            child: Text(
                              '비밀번호를 잊었다면?',
                              style: TextStyle(color: Colors.grey, fontSize: 15),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
            ),
            SizedBox(height: 20),
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: (){
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SignUpScreen()),
                  );
                },
                child: Text(
                  '지금 바로 회원가입  >',
                  style: TextStyle(
                      color: Colors.grey,
                      fontSize: 17,
                      fontWeight: FontWeight.w600
                  ),
                ),
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
                    onPressed: _trySignIn,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 26.0),
                      child: Text('로그인',style: TextStyle(fontSize: 18),),
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
