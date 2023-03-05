import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'main.dart';

class ScoreBar extends StatefulWidget {
  const ScoreBar({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ScoreBarState();
}

class _ScoreBarState extends State {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade800, Colors.indigo.shade300],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text(
              'Score: ${Provider.of<Data>(context).score}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
