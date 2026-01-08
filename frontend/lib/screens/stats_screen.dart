import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class StatsScreen extends StatefulWidget {
  final List<dynamic> drinksHistory;

  const StatsScreen({super.key, required this.drinksHistory});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  List<double> weeklyVolumes = [0, 0, 0, 0, 0, 0, 0];
  double maxVolume = 1000;

  @override
  void initState() {
    super.initState();
    _calculateWeeklyData();
  }

  void _calculateWeeklyData() {
    List<double> sums = [0, 0, 0, 0, 0, 0, 0];
    DateTime now = DateTime.now();
    
    // Resetăm la data de Luni a săptămânii curente
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    startOfWeek = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

    for (var drink in widget.drinksHistory) {
      String rawDate = drink['created_at'] ?? '';
      try {
        DateTime drinkDate = DateTime.parse(rawDate);
        DateTime dateOnly = DateTime(drinkDate.year, drinkDate.month, drinkDate.day);
        int diffDays = dateOnly.difference(startOfWeek).inDays;

        if (diffDays >= 0 && diffDays <= 6) {
          sums[diffDays] += (drink['volume_ml'] as num).toDouble();
        }
      } catch (e) {
        print("Eroare la parsare dată: $e");
      }
    }

    double calculatedMax = 0;
    for (var val in sums) {
      if (val > calculatedMax) calculatedMax = val;
    }

    setState(() {
      weeklyVolumes = sums;
      maxVolume = calculatedMax == 0 ? 1000 : calculatedMax * 1.2;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color barColor = Colors.blue;
    Color barBgColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;
    Color textColor = isDark ? Colors.white70 : Colors.black87;

    return Scaffold(
      appBar: AppBar(title: const Text("Statistici Săptămânale")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              "Consum Săptămâna Asta (ml)",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            
            Expanded(
              child: BarChart(
                BarChartData(
                  maxY: maxVolume,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${rod.toY.toInt()} ml',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 14);
                          String text;
                          switch (value.toInt()) {
                            case 0: text = 'L'; break;
                            case 1: text = 'M'; break;
                            case 2: text = 'M'; break;
                            case 3: text = 'J'; break;
                            case 4: text = 'V'; break;
                            case 5: text = 'S'; break;
                            case 6: text = 'D'; break;
                            default: text = '';
                          }
                          // --- AICI A FOST CORECȚIA ---
                          return SideTitleWidget(
                            meta: meta, // Folosim 'meta', nu 'axisSide'
                            space: 4,   // Putem adăuga și puțin spațiu
                            child: Text(text, style: style),
                          );
                          // ----------------------------
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  barGroups: _buildBars(barColor, barBgColor),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Total săptămâna asta: ${weeklyVolumes.reduce((a, b) => a + b).toInt()} ml",
              style: TextStyle(color: textColor, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBars(Color color, Color bgColor) {
    return List.generate(7, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: weeklyVolumes[index],
            color: color,
            width: 20,
            borderRadius: BorderRadius.circular(4),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxVolume,
              color: bgColor,
            ),
          ),
        ],
      );
    });
  }
}