import 'package:flutter/cupertino.dart';
import 'package:rive/rive.dart';

class AnimatedBtn extends StatelessWidget {
  const AnimatedBtn({
    super.key,
    required RiveAnimationController btnAnimationController,
    required this.press,
  }) : _btnAnimationController = btnAnimationController;

  final RiveAnimationController _btnAnimationController;
  final VoidCallback press;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: press,
      child: SizedBox(
        height: 64,
        width: 500,
        child: Stack(children: [
          RiveAnimation.asset(
            "assets/RiveAssets/button.riv",
            controllers: [_btnAnimationController],
          ),
          const Positioned.fill(
              top: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.arrow_right),
                  SizedBox(
                    width: 10,
                  ),
                  Text("Start now",
                      style: TextStyle(fontWeight: FontWeight.w600,fontSize: 17))
                ],
              )),
        ]),
      ),
    );
  }
}
