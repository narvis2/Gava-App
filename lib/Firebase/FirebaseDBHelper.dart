import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class FirebaseDBHelper {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String get userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  //USER PROFILE--------------
  Future<void> createUserProfile(String userId, String email, String profileImg, String nickname) async {
    await _firestore.collection('Users').doc(userId).set({
      'email': email,
      'profileImg': profileImg,
      'nickname': nickname,
      'quote': '',
    });
  }

  Future<UserProfile?> fetchUserProfile() async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('Users').doc(userId).get();
      if (userDoc.exists) {
        return UserProfile.fromFirestore(userDoc);
      } else {
        print("User profile not found");
        return null;
      }
    } catch (e) {
      print("Error fetching user profile: $e");
      return null;
    }
  }

  Future<void> updateUserProfile(String nickname, String quote) async {
    try {
      await _firestore.collection('Users').doc(userId).update({
        'nickname': nickname,
        'quote': quote,
      });
      print("User profile updated successfully");
    } catch (e) {
      print("Error updating user profile: $e");
      // Handle the exception as per your requirement
    }
  }

  //✅ DOLIST!!!!--------------------------------------------------------------
  Future<String> saveDoList(DoList doList) async {
    var doListData = {
      'title': doList.title,
      'image': doList.image,
      'importance': doList.importance,
      'done': doList.done,
      'startDate': doList.startDate,
      'endDate': doList.endDate,
      // Check for null doneTime before saving
      if (doList.doneTime != null) 'doneTime': Timestamp.fromDate(doList.doneTime!),
    };

    DocumentReference docRef = await _firestore
        .collection('Users')
        .doc(userId)
        .collection('DoList')
        .add(doListData);

    return docRef.id;
  }

  Future<DetailedDoList> saveDetailedDoList(String doListId, DetailedDoList detailedDoList) async {
    var detailedDoListData = detailedDoList.toFirestore();

    DocumentReference docRef = await _firestore
        .collection('Users')
        .doc(userId)
        .collection('DoList')
        .doc(doListId)
        .collection('DetailedDoList')
        .add(detailedDoListData);

    // Create a new DetailedDoList with the retrieved ID
    return DetailedDoList(
      id: docRef.id,
      title: detailedDoList.title,
      done: detailedDoList.done,
      doneTime: detailedDoList.doneTime,
    );
  }


  Stream<List<DetailedDoList>> getDetailedDoLists(String doListId) {
    return _firestore
        .collection('Users')
        .doc(userId)
        .collection('DoList')
        .doc(doListId)
        .collection('DetailedDoList')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => DetailedDoList.fromFirestore(doc))
        .toList());
  }

  Future<void> updateDoList(DoList doList) async {
    var doListData = {
      'title': doList.title,
      'image': doList.image,
      'importance': doList.importance,
      'done': doList.done,
      'startDate': doList.startDate,
      'endDate': doList.endDate,
    };

    await _firestore
        .collection('Users')
        .doc(userId)
        .collection('DoList')
        .doc(doList.id)
        .update(doListData);
  }

  Stream<List<DoList>> getUserDoLists() {
    var today = DateTime.now();
    return _firestore
        .collection('Users')
        .doc(userId)
        .collection('DoList')
        .where('done', isEqualTo: false)
        .where('endDate', isGreaterThanOrEqualTo: today.toIso8601String())
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => DoList.fromFirestore(doc)).toList();
    });
  }

  Future<List<DoList>> fetchDoneDoLists() async {
    List<DoList> doneDoLists = [];
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('Users')
          .doc(userId)
          .collection('DoList')
          .where('done', isEqualTo: true)
          .get();

      for (var doc in snapshot.docs) {
        doneDoLists.add(DoList.fromFirestore(doc));
      }
    } catch (e) {
      print('Error fetching done DoLists: $e');
    }
    return doneDoLists;
  }

  Future<Map<String, DateTime>> getStartAndEndDates() async {
    var earliestSnapshot = await FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .collection('DoList')
        .orderBy('startDate')
        .limit(1)
        .get();

    var latestSnapshot = await FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .collection('DoList')
        .orderBy('endDate', descending: true)
        .limit(1)
        .get();

    DateTime earliestDate;
    DateTime latestDate;

    if (earliestSnapshot.docs.isNotEmpty && latestSnapshot.docs.isNotEmpty) {
      var earliestData = earliestSnapshot.docs.first.data();
      var latestData = latestSnapshot.docs.first.data();

      // Check the type of startDate and endDate
      if (earliestData['startDate'] is Timestamp) {
        earliestDate = (earliestData['startDate'] as Timestamp).toDate();
      } else {
        earliestDate = DateTime.parse(earliestData['startDate']);
      }

      if (latestData['endDate'] is Timestamp) {
        latestDate = (latestData['endDate'] as Timestamp).toDate();
      } else {
        latestDate = DateTime.parse(latestData['endDate']);
      }
    } else {
      earliestDate = DateTime.now();
      latestDate = DateTime.now();
    }

    return {
      'earliestDate': earliestDate,
      'latestDate': latestDate,
    };
  }


  Future<double> calculateAverageTotalDoListItems() async {
    try {
      Map<String, DateTime> dates = await getStartAndEndDates();
      DateTime startDate = dates['earliestDate']!;
      DateTime endDate = dates['latestDate']!;

      var doListSnapshot = await _firestore
          .collection('Users')
          .doc(userId)
          .collection('DoList')
          .get();

      Map<DateTime, int> dateCounts = {};

      for (var doc in doListSnapshot.docs) {
        DateTime docStartDate = DateTime.parse(doc.data()['startDate']);
        DateTime docEndDate = DateTime.parse(doc.data()['endDate']);

        // Ensure the date range of the DoList item is within the start and end date range
        if (docStartDate.isBefore(endDate) && docEndDate.isAfter(startDate)) {
          for (DateTime date = docStartDate; date.isBefore(docEndDate.add(Duration(days: 1))); date = date.add(Duration(days: 1))) {
            // Normalize the date to remove the time part
            DateTime normalizedDate = DateTime(date.year, date.month, date.day);
            if (normalizedDate.isAfter(startDate) && normalizedDate.isBefore(endDate)) {
              dateCounts[normalizedDate] = (dateCounts[normalizedDate] ?? 0) + 1;
            }
          }
        }
      }

      int totalOccurrences = dateCounts.values.fold(0, (sum, count) => sum + count);
      int uniqueDaysCount = dateCounts.keys.length;

      if (uniqueDaysCount == 0) return 0.0; // Avoid division by zero
      return totalOccurrences / uniqueDaysCount;
    } catch (e) {
      print("Error in calculateAverageTotalDoListItems: $e");
      return 0.0;
    }
  }


  Future<double> calculateAverageDoneDoListItems() async {
    try {
      Map<String, DateTime> dates = await getStartAndEndDates();
      DateTime startDate = dates['earliestDate']!;
      DateTime endDate = dates['latestDate']!;

      var doListSnapshot = await _firestore
          .collection('Users')
          .doc(userId)
          .collection('DoList')
          .where('done', isEqualTo: true)
          .get();

      Map<DateTime, int> doneCountPerDay = {};

      for (var doc in doListSnapshot.docs) {
        if (doc.data().containsKey('doneTime')) {
          DateTime docDoneTime = (doc.data()['doneTime'] as Timestamp).toDate();
          // Ensure the doneTime is within the start and end date range
          if (docDoneTime.isAfter(startDate) && docDoneTime.isBefore(endDate)) {
            DateTime dateOnly = DateTime(docDoneTime.year, docDoneTime.month, docDoneTime.day);
            doneCountPerDay.update(dateOnly, (count) => count + 1, ifAbsent: () => 1);
          }
        }
      }

      if (doneCountPerDay.isEmpty) return 0.0; // Avoid division by zero

      int totalDoneCount = doneCountPerDay.values.reduce((a, b) => a + b);
      int dailyDoneCount = doneCountPerDay.keys.length; // Number of unique days

      return totalDoneCount / dailyDoneCount.toDouble();
    } catch (e) {
      print("Error in calculateAverageDoneDoListItems: $e");
      return 0.0;
    }
  }


  Future<List<DoList>> searchDoListByTitleAndDoneState(String title) async {
    List<DoList> matchingDoLists = [];

    try {
      // Create a range for the query to cover all titles starting with the input title
      String endTitle = title.substring(0, title.length - 1) + String.fromCharCode(title.codeUnitAt(title.length - 1) + 1);

      QuerySnapshot snapshot = await _firestore
          .collection('Users')
          .doc(userId)
          .collection('DoList')
          .where('done', isEqualTo: true)
          .orderBy('title')
          .startAt([title])
          .endAt([endTitle])
          .get();

      for (var doc in snapshot.docs) {
        DoList doList = DoList.fromFirestore(doc);
        matchingDoLists.add(doList);
      }
    } catch (e) {
      print('Error searching DoLists: $e');
    }

    return matchingDoLists;
  }


  Future<List<DetailedDoList>> fetchDetailedDoList(String doListId) async {
    List<DetailedDoList> detailedDoLists = [];

    QuerySnapshot snapshot = await _firestore
        .collection('Users')
        .doc(userId)
        .collection('DoList')
        .doc(doListId)
        .collection('DetailedDoList')
        .get();

    for (var doc in snapshot.docs) {
      DetailedDoList detailedDoList = DetailedDoList.fromFirestore(doc);
      detailedDoLists.add(detailedDoList);
    }

    return detailedDoLists;
  }

  Future<void> updateDetailedDoList( String doListId, String detailedDoListId, DetailedDoList detailedDoList) async {
    var detailedDoListData = detailedDoList.toFirestore();

    await _firestore
        .collection('Users')
        .doc(userId)
        .collection('DoList')
        .doc(doListId)
        .collection('DetailedDoList')
        .doc(detailedDoListId)
        .update(detailedDoListData);
  }

  Future<void> changeDoListState(String doListId, bool state) async {
    Map<String, dynamic> updates = {'done': state};

    // If marking as done, add the current time as doneTime
    if (state) {
      updates['doneTime'] = Timestamp.fromDate(DateTime.now());
    }

    await _firestore
        .collection('Users')
        .doc(userId)
        .collection('DoList')
        .doc(doListId)
        .update(updates);
  }


  Future<void> deleteDoList(String doListId) async {
    await _firestore
        .collection('Users')
        .doc(userId)
        .collection('DoList')
        .doc(doListId)
        .delete();
  }

  //📆SCHEDULES!!!!--------------------------------------------------------------
  Future<void> addNewSchedule(ScheduleData scheduleData) async {
    CollectionReference users = FirebaseFirestore.instance.collection('Users');
    await users.doc(userId).collection('Schedule').add(scheduleData.toMap());
  }

  // Inside FirebaseDBHelper class
  Future<void> updateScheduleDate(String docId, String newDate) async {
    await _firestore.collection('Users').doc(userId)
        .collection('Schedule').doc(docId)
        .update({'startDate': newDate});
  }

  Future<void> updateSchedule(ScheduleData scheduleData) async {
    try {
      await _firestore.collection('Users').doc(userId)
          .collection('Schedule').doc(scheduleData.docId)
          .update(scheduleData.toMap());
      print('Schedule updated successfully');
    } catch (e) {
      print('Error updating schedule: $e');
      // Handle the exception as per your requirement
    }
  }

  Future<Map<String, List<ScheduleData>>> fetchAndGroupUserSchedules() async {
    Map<String, List<ScheduleData>> groupedSchedules = {};

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('Users')
          .doc(userId)
          .collection('Schedule')
          .orderBy('startDate')
          .get();

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        ScheduleData schedule = ScheduleData.fromMap(data, doc.id); // Include doc ID

        // Group schedules by startDate
        if (!groupedSchedules.containsKey(schedule.startDate)) {
          groupedSchedules[schedule.startDate] = [];
        }
        groupedSchedules[schedule.startDate]?.add(schedule);
      }
    } catch (e) {
      print('Error fetching schedules: $e');
      // Handle the exception as per your requirement
    }

    return groupedSchedules;
  }

  Future<List<ScheduleData>> fetchSchedulesForDate(String date) async {
    List<ScheduleData> schedules = [];
    // Add logic to query Firebase Firestore to get schedules for the given date
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('Users')
        .doc(userId) // Assuming you have a userId defined
        .collection('Schedule')
        .where('startDate', isEqualTo: date)
        .get();

    for (var doc in snapshot.docs) {
      schedules.add(ScheduleData.fromMap(doc.data() as Map<String, dynamic>, doc.id));
    }

    return schedules;
  }

}

class UserProfile {
  final String email;
  final String profileImg;
  final String nickname;
  final String quote;

  UserProfile({
    required this.email,
    required this.profileImg,
    required this.nickname,
    required this.quote,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      email: data['email'] ?? '',
      profileImg: data['profileImg'] ?? '',
      nickname: data['nickname'] ?? '',
      quote: data['quote'] ?? '',

    );
  }
}


class DoList {
  final String id;
  final String title;
  final String image;
  final int importance;
  final bool done;
  final String startDate;
  final String endDate;
  final DateTime? doneTime;
  final List<DetailedDoList> detailedDoList;

  DoList({
    required this.id,
    required this.title,
    required this.image,
    required this.importance,
    required this.done,
    required this.startDate,
    required this.endDate,
    required this.doneTime,
    required this.detailedDoList,

  });

  factory DoList.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    List<DetailedDoList> detailedList = [];

    if (data['detailedDoList'] != null && data['detailedDoList'] is List) {
      detailedList = (data['detailedDoList'] as List)
          .map((item) {
        // Assuming each item in the list is a Map
        return DetailedDoList.fromFirestore(item as DocumentSnapshot);
      })
          .toList();
    }

    return DoList(
      id: doc.id,
      title: data['title'] ?? '',
      image: data['image'] ?? '',
      importance: data['importance'] ?? 0,
      done: data['done'] ?? false,
      startDate: data['startDate'] ?? '',
      endDate: data['endDate'] ?? '',
      doneTime: data['doneTime'] != null ? (data['doneTime'] as Timestamp).toDate() : null,
      detailedDoList: detailedList,
    );
  }

}

class DetailedDoList {
  final String id;
  String title;
  bool done;
  final DateTime? doneTime;

  DetailedDoList({
    this.id = '',
    required this.title,
    this.done = false,
    this.doneTime,
  });

  factory DetailedDoList.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return DetailedDoList(
      id: doc.id,
      title: data['title'] ?? '',
      done: data['done'] ?? false,
      doneTime: data['doneTime'] != null ? (data['doneTime'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'done': done,
      'doneTime': doneTime != null ? Timestamp.fromDate(doneTime!) : null,
    };
  }
}

class ScheduleData {
  String docId;
  String title;
  String image;
  int importance;
  String startDate;
  String startTime;
  String endDate;
  String endTime;
  bool notification;

  ScheduleData({
    required this.docId,
    required this.title,
    required this.image,
    required this.importance,
    required this.startDate,
    required this.startTime,
    required this.endDate,
    required this.endTime,
    required this.notification,
  });

  factory ScheduleData.fromMap(Map<String, dynamic> map, String docId) {
    return ScheduleData(
      docId: docId,
      title: map['title'] ?? '',
      image: map['image'] ?? '',
      importance: map['importance'] ?? 0,
      startDate: map['startDate'] ?? '',
      startTime: map['startTime'] ?? '',
      endDate: map['endDate'] ?? '',
      endTime: map['endTime'] ?? '',
      notification: map['notification'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'docId': docId,
      'title': title,
      'image': image,
      'importance': importance,
      'startDate': startDate,
      'startTime': startTime,
      'endDate': endDate,
      'endTime': endTime,
      'notification': notification,
    };
  }
}
