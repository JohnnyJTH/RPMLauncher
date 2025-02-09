import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rpmlauncher/Utility/I18n.dart';

class RWLLoading extends StatefulWidget {
  final bool animations;
  final bool logo;

  const RWLLoading({
    Key? key,
    this.animations = false,
    this.logo = false,
  }) : super(key: key);

  @override
  State<RWLLoading> createState() => _RWLLoadingState();
}

class _RWLLoadingState extends State<RWLLoading> {
  bool get animations => widget.animations;
  bool get logo => widget.logo;

  double _widgetOpacity = 0;

  List<String> tips = [
    // "RPMLauncher 第一開始不是這個名稱",
    // "RPMLauncher 第一開始其實叫做 MCSngLauncher",
    "rpmlauncher.tips.1",
    "rpmlauncher.tips.2",
  ];

  @override
  void initState() {
    if (animations) {
      Future.delayed(Duration(milliseconds: 400)).whenComplete(() => {
            if (mounted)
              {
                setState(() {
                  _widgetOpacity = 1;
                })
              }
          });
    }

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget _wdiget = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Builder(builder: (context) {
            if (logo) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset("assets/images/Logo.png", scale: 0.9),
                  SizedBox(
                    height: 10,
                  ),
                ],
              );
            } else {
              return SizedBox();
            }
          }),
          logo
              ? SizedBox(
                  width: MediaQuery.of(context).size.width / 5,
                  height: MediaQuery.of(context).size.height / 45,
                  child: LinearProgressIndicator())
              : CircularProgressIndicator(),
          Builder(builder: (context) {
            if (logo) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 10,
                  ),
                  Text(I18n.format('homepage.loading'),
                      style: TextStyle(fontSize: 35, color: Colors.lightBlue)),
                  SizedBox(
                    height: 10,
                  ),
                  I18nText("rpmlauncher.tips.title",
                      style:
                          TextStyle(fontSize: 15, fontStyle: FontStyle.italic)),
                  I18nText(tips.elementAt(Random().nextInt(tips.length)),
                      style: TextStyle(fontSize: 20)),
                ],
              );
            } else {
              return SizedBox();
            }
          }),
        ],
      ),
    );

    if (animations) {
      _wdiget = AnimatedOpacity(
          opacity: _widgetOpacity,
          duration: Duration(milliseconds: 700),
          child: _wdiget);
    }
    return _wdiget;
  }
}
