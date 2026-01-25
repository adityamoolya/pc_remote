import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/pc_provider.dart';

class MediaTab extends StatelessWidget {
  const MediaTab({super.key});

  @override
  Widget build(BuildContext context) {
    final pc = context.watch<PCProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Media Control')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          children: [
            // --- Volume Display ---
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 250,
                          height: 250,
                          child: CircularProgressIndicator(
                            value: pc.volume / 100,
                            strokeWidth: 20,
                            backgroundColor: Colors.white10,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${pc.volume}%',
                              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const Text(
                              'MASTER VOLUME',
                              style: TextStyle(
                                letterSpacing: 2,
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),
                    
                    // --- Slider ---
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 8,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
                      ),
                      child: Slider(
                        value: pc.volume.toDouble(),
                        min: 0,
                        max: 100,
                        onChanged: (v) => pc.setVolume(v.toInt()),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- Media Controls ---
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    iconSize: 32,
                    icon: const Icon(Icons.skip_previous_rounded),
                    onPressed: () => pc.mediaControl('prev'),
                  ),
                  IconButton.filled(
                    iconSize: 40,
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      padding: const EdgeInsets.all(16),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    onPressed: () => pc.mediaControl('playpause'),
                  ),
                  IconButton(
                    iconSize: 32,
                    icon: const Icon(Icons.skip_next_rounded),
                    onPressed: () => pc.mediaControl('next'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // --- Mute Button ---
            TextButton.icon(
              onPressed: () => pc.mediaControl('mute'),
              icon: const Icon(Icons.volume_off_outlined),
              label: const Text('Toggle Mute'),
              style: TextButton.styleFrom(foregroundColor: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
