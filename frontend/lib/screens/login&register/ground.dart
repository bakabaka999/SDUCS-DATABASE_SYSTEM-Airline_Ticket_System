import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'dart:math';

class AnimatedBackground extends StatefulWidget {
  @override
  _AnimatedBackgroundState createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _angleAnimations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 20),
    );

    // 创建多个Tween，每个Tween对应一个飞机的动画
    _angleAnimations = List.generate(
      10, // 假设我们要释放5架飞机
      (index) => Tween<double>(
        begin: index/5*2*pi+index*pi,
        end: 2 * pi+index/5*2*pi+index*pi,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.linear,
      )),
    );

    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        /*Center(
          child: CustomPaint(
            painter: BallPainter(),
            child: SizedBox(
              width: MediaQuery.of(context).size.shortestSide * 0.8,
              height: MediaQuery.of(context).size.shortestSide * 0.8,
            ),
          ),
        ),*/
        // 飞机动画
        ...List.generate(
          10, // 根据飞机数量生成多个PlaneAnimation
          (index) => PlaneAnimation(_angleAnimations[index], index),
        ),
      ],
    );
  }
}

class BallPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.teal
      ..style = PaintingStyle.fill;

    final double radius = size.shortestSide / 2;
    canvas.drawCircle(
      size.center(Offset.zero),
      radius,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class PlaneAnimation extends StatelessWidget {
  final Animation<double> angleAnimation;
  final int index; // 飞机的索引，用于区分不同的飞机

  PlaneAnimation(this.angleAnimation, this.index);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: angleAnimation,
      builder: (BuildContext context, Widget? child) {
        final ballDiameter = MediaQuery.of(context).size.shortestSide * 0.8;
        final ballRadius = ballDiameter / 2;
        final orbitRadius = ballRadius * (1.5 + index * 0.1+0.1*pow(-1,index)); // 为每架飞机分配不同的飞行半径
        final x = (MediaQuery.of(context).size.width / 2) +
            orbitRadius * cos(angleAnimation.value);
        final y = (MediaQuery.of(context).size.height / 2) +
            orbitRadius * sin(angleAnimation.value);
        return Transform.translate(
          offset: Offset(x, y),
          child: Transform.rotate(
            angle: angleAnimation.value + pi,
            child: Icon(
              Icons.airplanemode_active,
              size: 50 , // 根据索引减小飞机图标的大小，以区分不同的飞机
              color: Colors.teal,
            ),
          ),
        );
      },
    );
  }
}