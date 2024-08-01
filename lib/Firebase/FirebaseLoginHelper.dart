import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gava/TabbarScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseLoginHelper{

  //Login method : 📨EMAIL
  Future<void> emailSignUp(String email, String password) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // User has been successfully created
      FirebaseAuth.instance.currentUser!.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print('비밀번호가 취약합니다.');
      } else if (e.code == 'email-already-in-use') {
        print('이미 가입된 아이디입니다.');
      }
    } catch (e) {
      print(e); // Handle other errors
    }
  }

  Future<void> emailSignIn(String email, String password, BuildContext context) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => TabbarScreen()),
      );
    } catch (e) {
      print(e);
    }
  }

  Future<void> deleteCredentials() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('email');
    await prefs.remove('password');
  }

  Future<void> signOutUser() async {
    try {
      await FirebaseAuth.instance.signOut();
      deleteCredentials();
    } catch (e) {
      print("Error signing out: $e");
      // Handle exceptions, maybe show an alert to the user
    }
  }

  Future<void> deleteUserAccount() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        await user.delete();
        deleteCredentials();
        print("User account deleted successfully");
        // Handle post-deletion logic, like navigating to the login screen
      } else {
        print("No user is currently signed in");
      }
    } catch (e) {
      print("Error deleting user account: $e");
      // Handle exceptions, such as showing an alert to the user
    }
  }


}