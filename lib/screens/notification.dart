import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:studyscheduler/screens/Homescreen.dart';

class NotificationService {
  FlutterLocalNotificationsPlugin localNotifications =
  FlutterLocalNotificationsPlugin();

  // Fetch Access Token for sending notifications via FCM
  static Future<String> getAccessToken() async {
    const serviceAccountJson = {
      "type": "service_account",
      "project_id": "study-sprint-9c722",
      "private_key_id": "a010459c3fc273d7dd16297bcab33d4124118b0e",
      "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvwIBADANBgkqhkiG9w0BAQEFAASCBKkwggSlAgEAAoIBAQDOkGHPTJK3trf9\nix/vZEiV2XDsaO6kkMLg4on/Jhh0QYZgPN7ExPiidG/D4Jk2V2fKYX2LQDc/yP+G\nNeTp0Y9RCptQEOqqwZSiu7pq8bQvl31QHen4VIrGQIX8cByZMuxZeMosFRhRR7Hl\n5PtNtt/XH3XY2kHY88x5Un6JRCyJOJQ7FzT77SWpFYyQNvcHN4SFdbUgQWGPXlCd\n1MBVWwbAFgPlUXkLBN5rzV/4DNkb2kZ9UloREoQF35ZN4fK+H8VYtuJYCV8G6QfJ\nfFC9RgG78XqzK8VdSXPTcP4MS3a3KKw/IfEITz9lwEGEgNvh3IkTChdqTnZ2Kh7h\nvy1e+E4DAgMBAAECggEAA9IGsKPU60ruLcjbRyDAeSXsgU2Ea4WnrCsdVvChUu7n\nUJAhbGoFGIz8T0/o5YVmU7IEyr3BpEhB9gucd3jXiBFoCqLx57bQoYCMBYzIbVzp\nIhbCqLWxW9JwINlzT7xHQ+cIkcTRquARJFt5t0mw67SlJFadEWJFZqbQf6TDs+H6\nr6oaxZ7FvfkPFthiTewsmQ4tT6h6qg9Picc8frdNHjaCMoN/HLkrIVvpNC43G7xw\nGJKAqo2Fm0UlJUhL6nJBJLelCjD81CBUbdRs55fre6LqhUvyPQH6cq4IXw4hvheO\nUFyjgx3xTj4TuHHPSVyav3gCF7YEAYv/KTCK1o5FQQKBgQD8tyRJALiV3UbD0J3Z\nDqcUr2V/z7tF+DdOYbzhJBz2sF0BEZKfIrEHcsHiPW7wh9Ff7PCVdN40OzuGJMk2\n7n9bgqMFgxif9seBlfKss9wOkF+ju/H0S939V4tgREoG9wpxMtufycYUhglRwcAN\noRwTtaaW6hcc4BB2U2fqy4naIQKBgQDRP65ac3Ouc2E0SzhI38ClLMAh3zMhmflD\nSiCLNuriYVNQGUupNtvWcGN9hZxMdqf+l4e75GtIy6HK+9pdIS9XxdAYPNKKTxUi\nPuckU30nMjJp6s6f2CNqzJ2D7PocU09C1TU8kxuy/VHBWbiIHweKNhwXT6/1f6pS\nrMUIPXMLowKBgQDpPv+2gXvclkbiJIIL/IIpjVlZBhoLEnW5WmxCQFqbNVwhyF5T\nkmliPoDEl371ceXFa6MBzsPn4WOnA/zTPn09sO1WARGRUuwApq08ySSqLIaZULaY\njA1v7oUtbNoGY6y3ngEnEcxI1Q108CaabcDEUDxZveVnOUb4bzLSetnZAQKBgQDI\nOCvn5rLZSRPIyvTXXipiolhR0NWHIGLPTT2ol+rWpJPof9vS1WgzXyUDtXYiACOt\nS2cYlW9Gn3p31NdT5236iZAdsQ0wRI2PUCsxqiWF/NUaXhBKCLGS/qj11CpaMikU\nZRhklsqZUSUKYoRc03wOdsoYUCqpOPhL1X9O7CWKCwKBgQCrpefyID+A7YMd4/Oy\niHIi+GcRFiWXxmF454WwF/s1T7lyXoNEa0UF0w6BiyxgQ8oLV0O7rMkBH//pkvMa\nCWOx5y+CmQp+CTBuLyp3dLKV2AEzBqnEYNm7SZgrbqdD00341a6p6K/nk9Ir5Y2B\n/j2qlEXpEexQdMY0TE0mraEocg==\n-----END PRIVATE KEY-----\n",
      "client_email": "study-sprint@study-sprint-9c722.iam.gserviceaccount.com",
      "client_id": "113309715813609594159",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/study-sprint%40study-sprint-9c722.iam.gserviceaccount.com",
      "universe_domain": "googleapis.com"
    };

    List<String> scopes = [
      "https://www.googleapis.com/auth/firebase.messaging",
    ];

    var client = await auth.clientViaServiceAccount(
      auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
      scopes,
    );

    return (await auth.obtainAccessCredentialsViaServiceAccount(
        auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
        scopes,
        client))
        .accessToken
        .data;
  }
  // Send Notification
  static Future<void> sendNotification(
      String deviceToken, String title, String body) async {
    final String serverAccessToken = await getAccessToken();

    final Map<String, dynamic> message = {
      'message': {
        'token': deviceToken,
        'notification': {'title': title, 'body': body},
        'data': {'hello'}, // Add any extra custom data
      }
    };

    final http.Response response = await http.post(
      Uri.parse(
          'https://fcm.googleapis.com/v1/projects/study-sprint-9c722/messages:send'),
      headers: {
        'Authorization': 'Bearer $serverAccessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(message),
    );

    if (response.statusCode == 200) {
      print("Notification sent successfully");
    } else {
      print("Error sending notification: ${response.body}");
    }
  }

  // // Initialize Local Notifications
  // void initLocalNotification(BuildContext context, RemoteMessage message) {
  //   var androidInitSettings = const AndroidInitializationSettings("@mipmap/launcher_icon");
  //   var iosInitSettings = const DarwinInitializationSettings();
  //   var initSettings = InitializationSettings(
  //     android: androidInitSettings,
  //     iOS: iosInitSettings,
  //   );
  //
  //   localNotifications.initialize(initSettings, onDidReceiveNotificationResponse: (payload) {
  //     handleMessage(context, message);
  //   });
  // }
  //
  // void firebaseInit(BuildContext context){
  //   FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  //     RemoteNotification? notification = message.notification;
  //     AndroidNotification? androidNotification = message.notification!.android;
  //
  //     if(kDebugMode){
  //       print("Foreground Notification: ${notification!.title}, ${notification.body}");
  //     }
  //
  //     if(Platform.isAndroid){
  //       initLocalNotification(context, message);
  //      showNotification(message);
  //     }
  //   });
  // }

  // //function to show notification
  // Future<void> showNotification(RemoteMessage message)async{
  //   AndroidNotificationChannel channel= AndroidNotificationChannel(message.notification!.android!.channelId.toString(), message.notification!.android!.channelId.toString(),
  //   importance: Importance.high,
  //   showBadge: true,
  //   playSound: true);
  //   AndroidNotificationDetails androidNotificationDetails= AndroidNotificationDetails(channel.toString(), channel.toString(),channelDescription: "channel descripption",importance: Importance.high,playSound: true,priority: Priority.high,sound: channel.sound);
  //
  //   NotificationDetails notificationDetails=NotificationDetails(
  //     android: androidNotificationDetails,
  //   );
  //
  //   //show notification
  //   Future.delayed(Duration.zero,()
  //   {
  //     localNotifications.show(0, message.notification!.title.toString(), message.notification!.body.toString(), notificationDetails,payload: "my_data");
  //   });
  // }
  //
  // //background message
  //  Future<void> setupInteractMessage(BuildContext context)async{
  //   // background state
  //    FirebaseMessaging.onMessageOpenedApp.listen((message)
  //    {
  //      handleMessage(context, message);
  //    });
  //
  //    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message)
  //    {
  //      if(message!=null && message.data.isNotEmpty){
  //        handleMessage(context, message);
  //      }
  //    });
  //  }
  //
  // Future<void> handleMessage(BuildContext context,RemoteMessage message)async{
  //   Navigator.push(context, MaterialPageRoute(builder: (context) => StudySprintHomeScreen(),));
  // }
}
