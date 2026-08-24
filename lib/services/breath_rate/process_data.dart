// SPDX-License-Identifier: AGPL-3.0-only
import 'dart:async';
import 'dart:typed_data';
import 'dart:developer' as developer;
import 'dart:convert';
import 'package:breath_state/constants/file_constants.dart';
import 'package:breath_state/services/file_service/file_write.dart';

class ProcessData {
  late StreamController<List<Int16List>> recorderDataController;
  late List<int> averageStreamList = List.empty(growable: true);
  int numberOfSamples = 0;                                 
  int windowSize = 10;
  int minGap = 80;

  final fileWriter = FileWriterService();

  Future<void> getStream(StreamController<List<Int16List>> recorder) async {
    recorderDataController = recorder;
    await for (var value in recorderDataController.stream) {
      for (var chunk in value) {
        int average = (chunk.reduce((a, b) => a + b) ~/ chunk.length).abs();
        numberOfSamples += chunk.length;
        averageStreamList.add(average);
      }
    }
  }

  Future<int> calculateBreathRate() async {
    List<int> amplitudes = averageStreamList;

    List<int> smoothed = [];

    for (int i = 0; i < amplitudes.length; i++) {
      int start = (i - windowSize ~/ 2).clamp(0, amplitudes.length - 1);
      int end = (i + windowSize ~/ 2).clamp(0, amplitudes.length - 1);
      int sum = 0;
      int count = 0;

      for (int j = start; j <= end; j++) {
        sum += amplitudes[j];
        count++;
      }

      smoothed.add((sum / count).round());
    }

    double average = smoothed.reduce((a, b) => a + b) / smoothed.length;

    int numberOfPeaks = 0;
    bool above = false;
    int lastPeakIndex = -1 * minGap;

    for (int i = 0; i < smoothed.length; i++) {
      int amp = smoothed[i];

      if (!above && amp > average) {
        if (i - lastPeakIndex >= minGap) {
          numberOfPeaks++;
          lastPeakIndex = i;
        }
        above = true;
      } else if (above && amp < average) {
        above = false;
      }
    }

    double bpm = numberOfPeaks * (60.0 / 30.0);
                                                                       
    final timestamp = DateTime.now().toIso8601String();
    final data = {
      "timestamp": timestamp,
      "breathingRate": double.parse(bpm.toStringAsFixed(2)),
      "smoothedData": smoothed,
    };

    try {
      await fileWriter.writeStringToFile(jsonEncode(data), BREATH_FILE_NAME);
    } catch (e) {
      developer.log("Error saving breathing data as JSON: $e");
    }

    return bpm.round();
  }
}
