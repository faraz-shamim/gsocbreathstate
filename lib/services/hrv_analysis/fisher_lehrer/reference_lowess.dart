// SPDX-License-Identifier: AGPL-3.0-only
import 'dart:math' as math;

                                               
   
                                                                            
                                                  
List<double> fisherLehrerLowess(
  List<double> x,
  List<double> y,
  int neighborhoodPoints,
) {
  if (x.length != y.length) {
    throw ArgumentError('x and y must have the same length');
  }
  if (x.isEmpty) return const [];
  if (neighborhoodPoints < 3) {
    throw ArgumentError.value(
      neighborhoodPoints,
      'neighborhoodPoints',
      'must be at least 3',
    );
  }

  final lastIndex = x.length - 1;
  final output = List<double>.filled(x.length, 0);
  final distance = List<double>.filled(x.length, 0);

  for (var pointIndex = 0; pointIndex <= lastIndex; pointIndex++) {
    final xNow = x[pointIndex];
    for (var index = 0; index <= lastIndex; index++) {
      distance[index] = (x[index] - xNow).abs();
    }

    var minimumIndex = 0;
    var maximumIndex = lastIndex;
    while (maximumIndex + 1 - minimumIndex > neighborhoodPoints) {
      if (distance[minimumIndex] > distance[maximumIndex]) {
        minimumIndex++;
      } else if (distance[minimumIndex] < distance[maximumIndex]) {
        maximumIndex--;
      } else {
        minimumIndex++;
        maximumIndex--;
      }
    }

    var maximumDistance = -1.0;
    for (var index = minimumIndex; index <= maximumIndex; index++) {
      maximumDistance = math.max(maximumDistance, distance[index]);
    }
    if (maximumDistance <= 0) {
      output[pointIndex] = xNow;
      continue;
    }

    var sumWeights = 0.0;
    var sumWeightedX = 0.0;
    var sumWeightedX2 = 0.0;
    var sumWeightedY = 0.0;
    var sumWeightedXY = 0.0;

    for (var index = minimumIndex; index <= maximumIndex; index++) {
      final scaledDistance = distance[index] / maximumDistance;
      final weight = math.pow(1 - math.pow(scaledDistance, 3), 3).toDouble();
      sumWeights += weight;
      sumWeightedX += x[index] * weight;
      sumWeightedX2 += x[index] * x[index] * weight;
      sumWeightedY += y[index] * weight;
      sumWeightedXY += x[index] * y[index] * weight;
    }

    final denominator =
        sumWeights * sumWeightedX2 - sumWeightedX * sumWeightedX;
    if (denominator == 0 || !denominator.isFinite) {
      output[pointIndex] = xNow;
      continue;
    }

    final slope =
        (sumWeights * sumWeightedXY - sumWeightedX * sumWeightedY) /
        denominator;
    final intercept =
        (sumWeightedX2 * sumWeightedY - sumWeightedX * sumWeightedXY) /
        denominator;
    output[pointIndex] = slope * xNow + intercept;
  }

  return output;
}
