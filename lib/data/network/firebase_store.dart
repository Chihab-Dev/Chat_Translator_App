import 'dart:async';

import 'package:chat_translator/core/utlis/constances.dart';
import 'package:chat_translator/data/models/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class FirebaseStore {
  Future<String> addNewUserToFirestore(CustomerModel userModel);
  Future<CustomerModel> getUserDataById(String id);
  Future<List<CustomerModel>> getAllUsers();
  Future<void> sentMessageToUserFirebase(MessageModel message);
  Future<void> sentTranslatedMsgToFriendFirebase(MessageModel translatedMsg);
  Future<List<MessageModel>> getMessagesByFriendId(String myFriendId, String myId);
  Stream<List<MessageModel>> getStreamMessages(String myFriendId, String myId);
  Stream<MessageModel> getLastMessage(String myFriendId, String myId);
  Future<void> updateTypingStatus(String myFriendId, String myId, bool typingStatus);
  Stream<bool> getTypingStatus(String myFriendId, String myId);
  Stream<bool> getIsUserOnline(String myFriendId);
  Future<void> updateUserOnlineStatus(String userId, bool status);
}

class FirebaseStoreImpl implements FirebaseStore {
  final FirebaseFirestore _firebaseFirestore;

  FirebaseStoreImpl(this._firebaseFirestore);

  @override
  Future<String> addNewUserToFirestore(CustomerModel userModel) async {
    try {
      await _firebaseFirestore.collection(FirebaseConstance.users).doc(userModel.id).set(
            userModel.toJson(),
          );
      return userModel.id;
    } on FirebaseException catch (e) {
      print("🛑 error addNewUserToFirestore");
      print(e.message);
      rethrow;
    }
  }

  @override
  Future<CustomerModel> getUserDataById(String id) async {
    try {
      return await _firebaseFirestore.collection(FirebaseConstance.users).doc(id).get().then(
        (value) {
          print(value.data());
          return CustomerModel.fromJson(value.data()!);
        },
      ).catchError((onError) {
        print("🫣🫣");
        print(onError.toString());
        throw onError;
      });
    } on FirebaseException {
      print("🫣");

      rethrow;
    }
  }

  @override
  Future<List<CustomerModel>> getAllUsers() async {
    try {
      QuerySnapshot querySnapshot = await _firebaseFirestore.collection(FirebaseConstance.users).get();

      List<CustomerModel> usersList = [];

      for (var doc in querySnapshot.docs) {
        usersList.add(CustomerModel.fromJson(doc.data() as Map<String, dynamic>));
      }

      return usersList;
    } on FirebaseException catch (e) {
      print("Error getting all users: $e");
      rethrow;
    }
  }

  @override
  Future<void> sentMessageToUserFirebase(MessageModel message) async {
    try {
      _firebaseFirestore
          .collection(FirebaseConstance.users)
          .doc(message.senderId)
          .collection(FirebaseConstance.chats)
          .doc(message.receiverId)
          .collection(FirebaseConstance.messages)
          .add(message.toJson());
      print("sent message succes");
    } on FirebaseException catch (e) {
      print("error sentMessageToUserFirebase $e");
      rethrow;
    }
  }

  @override
  Future<void> sentTranslatedMsgToFriendFirebase(MessageModel translatedMsg) async {
    try {
      _firebaseFirestore
          .collection(FirebaseConstance.users)
          .doc(translatedMsg.receiverId)
          .collection(FirebaseConstance.chats)
          .doc(translatedMsg.senderId)
          .collection(FirebaseConstance.messages)
          .add(translatedMsg.toJson());
      print("sentTranslatedMsgToFriendFirebase");
    } on FirebaseException catch (e) {
      print("error sentTranslatedMsgToFriendFirebase $e");
      rethrow;
    }
  }

  @override
  Future<List<MessageModel>> getMessagesByFriendId(String myFriendId, String myId) async {
    try {
      List<MessageModel> messageList = [];
      QuerySnapshot querySnapshot = await _firebaseFirestore
          .collection(FirebaseConstance.users)
          .doc(myId)
          .collection(FirebaseConstance.chats)
          .doc(myFriendId)
          .collection(FirebaseConstance.messages)
          .get();

      for (var doc in querySnapshot.docs) {
        messageList.add(MessageModel.fromJson(doc.data() as Map<String, dynamic>));
      }
      print("getMessagesByFriendId");

      return messageList;
    } on FirebaseException {
      print("error getMessagesByFriendId");
      rethrow;
    }
  }

  // @override
  // Stream<List<MessageModel>> getStreamMessagdes(String myFriendId, String myId) {
  //   List<MessageModel> messages = [];
  //   _firebaseFirestore
  //       .collection(FirebaseConstance.users)
  //       .doc(myId)
  //       .collection(FirebaseConstance.chats)
  //       .doc(myFriendId)
  //       .collection(FirebaseConstance.messages)
  //       .orderBy('dateTime')
  //       .snapshots()
  //       .listen((event) {
  //     messages = [];
  //     for (var element in event.docs) {
  //       messages.add(MessageModel.fromJson(element.data()));
  //     }
  //   });
  // }

  @override
  Stream<List<MessageModel>> getStreamMessages(String myFriendId, String myId) {
    StreamController<List<MessageModel>> streamController = StreamController<List<MessageModel>>();

    _firebaseFirestore
        .collection(FirebaseConstance.users)
        .doc(myId)
        .collection(FirebaseConstance.chats)
        .doc(myFriendId)
        .collection(FirebaseConstance.messages)
        .orderBy(FirebaseConstance.dataTime)
        .snapshots()
        .listen((event) {
      List<MessageModel> messagesList = [];

      for (var element in event.docs) {
        messagesList.add(MessageModel.fromJson(element.data()));
      }

      streamController.add(messagesList);
    });

    return streamController.stream;
  }

  @override
  Stream<MessageModel> getLastMessage(String myFriendId, String myId) {
    try {
      return _firebaseFirestore
          .collection(FirebaseConstance.users)
          .doc(myId)
          .collection(FirebaseConstance.chats)
          .doc(myFriendId)
          .collection(FirebaseConstance.messages)
          .orderBy(FirebaseConstance.dataTime, descending: true)
          .limit(1)
          .snapshots()
          .map(
        (querySnapshot) {
          if (querySnapshot.docs.isNotEmpty) {
            return MessageModel.fromJson(querySnapshot.docs.first.data());
          } else {
            return MessageModel('', '', '', '');
          }
        },
      );
    } catch (e) {
      print("Error getting last message stream: $e");
      rethrow;
    }
  }

  @override
  Future<void> updateTypingStatus(String myFriendId, String myId, bool typingStatus) async {
    var chatReference = _firebaseFirestore
        .collection(FirebaseConstance.users)
        .doc(myFriendId)
        .collection(FirebaseConstance.chats)
        .doc(myId);

    // var chatDocument = await chatReference.get();

    await chatReference.set({
      'typingStatus': typingStatus,
    }, SetOptions(merge: true));
    // if (chatDocument.exists) {
    //   var chatData = chatDocument.data();
    //   if (chatData != null) {
    //     // Update the 'typingStatus' field, whether it's null or not
    //     await chatReference.set({
    //       'typingStatus': typingStatus,
    //     }, SetOptions(merge: true));
    //   }
    // }
  }

  @override
  Stream<bool> getTypingStatus(String myFriendId, String myId) {
    return _firebaseFirestore
        .collection(FirebaseConstance.users)
        .doc(myId)
        .collection(FirebaseConstance.chats)
        .doc(myFriendId)
        .snapshots()
        .map((docSnapshot) {
      if (docSnapshot.exists) {
        var chatData = docSnapshot.data();
        return chatData?['typingStatus'] ?? false;
      } else {
        return false;
      }
    });
  }

  @override
  Stream<bool> getIsUserOnline(String userId) {
    return _firebaseFirestore.collection(FirebaseConstance.users).doc(userId).snapshots().map((docSnapshot) {
      if (docSnapshot.exists) {
        var userData = docSnapshot.data();
        return userData?['isUserOnline'] ?? false;
      } else {
        return false;
      }
    });
  }

  @override
  Future<void> updateUserOnlineStatus(String userId, bool status) async {
    await _firebaseFirestore.collection(FirebaseConstance.users).doc(userId).update(
      {'isUserOnline': status},
    );
  }
}
