import 'package:flutter/material.dart';

class ControlsScreen extends StatefulWidget {
  const ControlsScreen({super.key});

  @override
  State<ControlsScreen> createState() => _ControlsScreenState();
}

class _ControlsScreenState extends State<ControlsScreen> {
  double _currentValue = 50; // initial slider value

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // First row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  print('Lock PC pressed');
                },
                child: const Text('Lock PC'),
              ),
              ElevatedButton(
                onPressed: () {
                  print('Sleep PC pressed');
                },
                child: const Text('Sleep PC'),
              ),
              ElevatedButton(
                onPressed: () {
                  print('Shutdown pressed');
                },
                child: const Text('Shutdown'),
              ),
            ],
          ),

          const SizedBox(height: 16), // space between rows

          // Second row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  print('Task Manager pressed');
                },
                child: const Text('Task Mgr'),
              ),
              ElevatedButton(
                onPressed: () {
                  print('Play/Pause pressed');
                },
                child: const Text('Play/Pause'),
              ),
            ],
          ),

          const SizedBox(height: 16), // space before slider

          // Third row: Slider
          Container(
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Slider(
                    value: _currentValue,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    label: _currentValue.round().toString(),
                    onChanged: (double value) {
                      setState(() {
                        _currentValue = value;
                      });
                      print('Slider value: $_currentValue');
                    },
                  ),
                ),
                Text('Volume: ${_currentValue.round()}'),


              ],
            ),
          ),
        ],
      ),
    );
  }
}
