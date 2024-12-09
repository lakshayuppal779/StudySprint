import 'package:flutter/material.dart';
import 'package:studyscheduler/flutter_gemini/chat_screen.dart';
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Future.delayed(const Duration(seconds: 1), (){
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=> const ChatScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        height: double.infinity,
        width: double.infinity,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 130,
              ),
              SizedBox(
                  height: 400,
                  width: 400,
                  child: Image.asset('assets/images/gemini.png')
              ),
              SizedBox(
                height: 80,
              ),
              const Text(
                'Flutter',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800
               ),
              ),
              SizedBox(height: 3,),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.electric_bolt_sharp,color: Colors.white,),
                  Text('Lakshay',style: TextStyle(fontSize: 13,fontWeight: FontWeight.w500,color: Colors.white),)
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

