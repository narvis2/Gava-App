import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gava/configure/configure.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MemoScreen extends StatefulWidget {
  @override
  _MemoScreenState createState() => _MemoScreenState();
}

class _MemoScreenState extends State<MemoScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? selectedDoListId;
  String? selectedDoListTitle;
  String get userId => FirebaseAuth.instance.currentUser?.uid ?? '';
  List<String> memos = [];

  @override
  void initState() {
    super.initState();
    _fetchFirstDoList();
    memos.add('새로운 메모');
  }

  Future<void> _fetchFirstDoList() async {
    var snapshot = await _firestore.collection('Users').doc(userId).collection('DoList').limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      var firstDoList = snapshot.docs.first;
      setState(() {
        selectedDoListId = firstDoList.id;
        selectedDoListTitle = firstDoList.data()['title'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(left: 23,right: 23, top: 60),
            child:Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: TextButton(
                      child: Text(
                        '${selectedDoListTitle ?? '계획선택'} ',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                      onPressed: _showDoListSelection,
                    ),
                  ),
                ),
                Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      decoration: BoxDecoration(
                          color: PRIMARY_COLOR,
                          borderRadius: BorderRadius.circular(12)
                      ),
                      child: IconButton(
                          onPressed: _addNewMemo,
                          icon: Icon(Icons.add, color: Colors.white,)
                      ),
                    )
                )
              ],
            ),
          ),
          Expanded(
            child: Container(
              child: ListView.builder(
                itemCount: memos.length,
                itemBuilder: (context, index) {
                  return Card(
                    color: Color(0xFF1E1E1E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      title: Text(
                        memos[index],
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      trailing: Container(
                        decoration: BoxDecoration(
                            color: Color(0xff444444),
                            borderRadius: BorderRadius.circular(12)
                        ),
                        height: 32,
                        width: 32,
                        child: Icon(Icons.add, color: Colors.white,size: 20,),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      )
    );
  }

  Future<void> _showDoListSelection() async {
    var result = await showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('Users').doc(userId).collection('DoList').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData) {
              return Center(child: Text('No DoLists found', style: TextStyle(color: Colors.white)));
            }

            var doLists = snapshot.data!.docs;

            return Container(
              padding: EdgeInsets.symmetric(horizontal: 23, vertical: 25),
              decoration: BoxDecoration(
                color: SECONDARY_COLOR,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: ListView.builder(
                itemCount: doLists.length,
                itemBuilder: (context, index) {
                  var doList = doLists[index];
                  bool isSelected = selectedDoListId == doList.id;

                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    padding: EdgeInsets.symmetric(vertical: 7, horizontal: 10),
                    decoration: BoxDecoration(
                      color: Color(0xff252525),
                      borderRadius: BorderRadius.circular(24),
                      border: isSelected ? Border.all(color: PRIMARY_COLOR, width: 2) : null,
                    ),
                    child: ListTile(
                      title: Text(doList['title'], style: TextStyle(color: Colors.white)),
                      onTap: () {
                        Navigator.pop(context, {
                          'selectedDoListId': doList.id,
                          'selectedDoListTitle': doList['title'],
                        });
                      },
                    ),
                  );
                },
              ),
            );
          },
        );
      },
      backgroundColor: Colors.transparent, // Making background transparent
      // isScrollControlled: true, // For full screen modal
      shape: RoundedRectangleBorder( // Adding shape to the modal bottom sheet
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        selectedDoListId = result['selectedDoListId'];
        selectedDoListTitle = result['selectedDoListTitle'];
      });
    }
  }


  Future<void> _addNewMemo() async {
    if (selectedDoListId == null || selectedDoListTitle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('계획을 먼저 선택해주세요'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    DocumentReference newMemoRef = _firestore
        .collection('Users')
        .doc(userId)
        .collection('DoList')
        .doc(selectedDoListId)
        .collection('Memo')
        .doc();

    await newMemoRef.set({
      'content': '',
      'title': '',
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('새로운 메모가 추가되었어요.'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

