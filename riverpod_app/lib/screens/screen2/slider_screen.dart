// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_app/screens/screen2/slider_provider.dart';

class SliderScreen extends ConsumerStatefulWidget {
  const SliderScreen({super.key});

  @override
  ConsumerState<SliderScreen> createState() => _SliderScreenState();
}

class _SliderScreenState extends ConsumerState<SliderScreen> {
  @override
  Widget build(BuildContext context) {
    print('print1');
    return Scaffold(
      appBar: AppBar(title: const Text("Counter App")),
      body: Column(
        mainAxisAlignment: .center,
        children: [
          Consumer(
            builder: (context, ref, child) {
              print("eye");
              final slider = ref.watch(
                sliderProvider.select((state) => state.showPassword),
              );
              print('print2');
              return InkWell(
                onTap: () {
                  final statePovider = ref.read(sliderProvider.notifier);
                  statePovider.state = statePovider.state.copyWith(
                    showPassword: !slider,
                  );
                },
                child: SizedBox(
                  height: 200,
                  width: 200,
                  child: slider
                      ? Icon(Icons.remove_red_eye)
                      : Icon(Icons.hide_source),
                ),
              );
            },
          ),
          Consumer(
            builder: (context, ref, child) {
              final slider = ref.watch(sliderProvider);
              print('print2');
              return Container(
                height: 200,
                width: 200,
                color: Colors.red.withOpacity(slider.slider),
              );
            },
          ),
          Consumer(
            builder: (context, ref, child) {
              final slider = ref.watch(
                sliderProvider.select((state) => state.slider),
              );
              print('print3');
              return Slider(
                value: slider,
                onChanged: (value) {
                  final statePovider = ref.read(sliderProvider.notifier);
                  statePovider.state = statePovider.state.copyWith(
                    slider: value,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
