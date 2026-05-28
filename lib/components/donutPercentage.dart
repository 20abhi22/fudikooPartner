import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class DonutChart extends StatelessWidget {
  final double percentage;

  const DonutChart({super.key, required this.percentage});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            sectionsSpace: 0,
            centerSpaceRadius: 50,
            startDegreeOffset: -90,
            sections: [
              PieChartSectionData(
                value: percentage,
                color: Colors.deepOrange,
                radius: 50,
                title: '',
              ),
              PieChartSectionData(
                value: 1 - percentage,
                color: Colors.deepOrange.shade100,
                radius: 50,
                title: '',
              ),
            ],
          ),
        ),
        Text(
          '${(percentage * 100).toStringAsFixed(1)}%',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
