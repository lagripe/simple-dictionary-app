import 'dart:async';
import 'dart:core';
import 'package:astaray/StaticalObjects.dart';
import 'Home.dart';
import 'package:flutter/material.dart';
import 'package:responsive_container/responsive_container.dart';
import 'dart:async' show Timer;

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    StaticalObject.initCache();
    print(StaticalObject.bookmark.length);
    // TODO: implement initState
    super.initState();
    Timer(Duration(seconds: 5), () {
      
      Navigator.pop(context);
      Navigator.push(context,
          MaterialPageRoute(builder: (BuildContext context) => Home()));
    });
  }
  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      body:  ResponsiveContainer(
              heightPercent: 100,
              widthPercent: 100,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Image.asset('assets/icon.png',),
                  CircularProgressIndicator(
                              strokeWidth: 5,
                              
                            )
                ],
              )),
    );
  }
}
