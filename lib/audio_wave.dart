import 'package:flutter/material.dart';

class AudioWaveBar extends StatefulWidget {
  const AudioWaveBar({
    Key? key,
    required this.color,
    required this.duration,
  }) : super(key: key);
  final Color color;
  final int duration;
  @override
  _AudioWaveBarState createState() => _AudioWaveBarState();
}

class _AudioWaveBarState extends State<AudioWaveBar>
    with SingleTickerProviderStateMixin {
  late Animation<double> _animation;
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.duration),
    );
    final curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _animation = Tween<double>(begin: 10.0, end: 64.0).animate(curvedAnimation)
      ..addListener(() {
        setState(() {});
      });
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10.0,
      height: _animation.value,
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(6.0),
      ),
    );
  }
}

class AudioWave extends StatelessWidget {
  const AudioWave({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<int> durations = [900, 600, 800, 500, 700, 400];
    final List<Color> colors = [
      Colors.white,
      Colors.blueAccent.shade700,
      Colors.red.shade800,
      Colors.deepPurpleAccent.shade700,
    ];
    return SizedBox(
      width: 300.0,
      height: 100.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ...List.generate(
            10,
            (index) => AudioWaveBar(
              color: colors[index % 4],
              duration: durations[index % 6],
            ),
          ),
        ],
      ),
    );
  }
}
