import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _showDotGraph = false;

  void _showScoreDialog(BuildContext context,
      {SubjectScore? existingScore, int? index}) {
    final settingsBox = Hive.box<UserSettings>('user_settings');
    final settings = settingsBox.get('settings');
    final isNeet = settings?.type != AspirantType.jee;
    final maxAllowed = isNeet ? 720 : 300;

    final scoreController = TextEditingController(
      text: existingScore != null ? existingScore.score.toInt().toString() : '',
    );
    DateTime selectedDate = existingScore?.date ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          existingScore == null ? 'Add Mock Test' : 'Edit Score',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: scoreController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Total Score',
                    hintText: 'Max $maxAllowed',
                    prefixIcon: const Icon(Icons.score_outlined),
                    suffixText: '/ $maxAllowed',
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: Text(
                    DateFormat.yMMMd().format(selectedDate),
                    style: GoogleFonts.outfit(),
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2024),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(scoreController.text) ?? 0.0;
              if (val > maxAllowed) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Score cannot exceed $maxAllowed')),
                );
                return;
              }

              final box = Hive.box<SubjectScore>('subject_scores');
              final newScore = SubjectScore(
                subjectName: 'Total', // We use 'Total' as a generic key now
                score: val,
                maxScore: maxAllowed.toDouble(),
                date: selectedDate,
              );

              if (index != null) {
                box.putAt(index, newScore);
              } else {
                box.add(newScore);
              }

              Navigator.pop(context);
            },
            child: Text(existingScore == null ? 'Save' : 'Update'),
          ),
        ],
      ),
    );
  }

  void _deleteScore(int index) {
    Hive.box<SubjectScore>('subject_scores').deleteAt(index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: ValueListenableBuilder(
        valueListenable: Hive.box<SubjectScore>('subject_scores').listenable(),
        builder: (context, Box<SubjectScore> box, _) {
          if (box.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart_outlined,
                      size: 80, color: theme.colorScheme.primary.withAlpha(50)),
                  const SizedBox(height: 16),
                  Text(
                    'No entries yet.',
                    style: GoogleFonts.outfit(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Log your mock test scores to see trends.',
                    style: GoogleFonts.outfit(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final scores = box.values.toList();
          // Sort for the chart
          final sortedScores = List<SubjectScore>.from(scores)
            ..sort((a, b) => a.date.compareTo(b.date));

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Performance',
                        style: GoogleFonts.outfit(
                            fontSize: 28, fontWeight: FontWeight.w900),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: Icon(_showDotGraph
                              ? Icons.show_chart
                              : Icons.scatter_plot_outlined),
                          onPressed: () =>
                              setState(() => _showDotGraph = !_showDotGraph),
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Chart Card
              SliverToBoxAdapter(
                child: Container(
                  height: 250,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.fromLTRB(8, 24, 24, 16),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(24),
                    border: theme.cardTheme.shape is RoundedRectangleBorder
                        ? Border.fromBorderSide(
                            (theme.cardTheme.shape as RoundedRectangleBorder)
                                .side)
                        : null,
                  ),
                  child: _showDotGraph
                      ? _buildScatterChart(sortedScores, theme)
                      : _buildLineChart(sortedScores, theme),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'History',
                    style: GoogleFonts.outfit(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      // Reverse index for list to show latest first
                      final actualIndex = box.length - 1 - index;
                      final data = box.getAt(actualIndex)!;
                      final percentage = (data.score / data.maxScore) * 100;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: _getScoreColor(percentage).withAlpha(30),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                '${percentage.toInt()}%',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  color: _getScoreColor(percentage),
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            '${data.score.toInt()} / ${data.maxScore.toInt()}',
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w900, fontSize: 18),
                          ),
                          subtitle: Text(DateFormat.yMMMd().format(data.date)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                onPressed: () => _showScoreDialog(context,
                                    existingScore: data, index: actualIndex),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 20, color: Colors.redAccent),
                                onPressed: () => _deleteScore(actualIndex),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: box.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showScoreDialog(context),
        label: const Text('Add Test'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 50) return Colors.orange;
    return Colors.red;
  }

  Widget _buildLineChart(List<SubjectScore> scores, ThemeData theme) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: theme.dividerColor.withAlpha(30), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
              sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (val, meta) => Text(val.toInt().toString(),
                      style: TextStyle(
                          fontSize: 10,
                          color: theme.colorScheme.onSurface.withAlpha(100))))),
          bottomTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: scores
                .asMap()
                .entries
                .map((e) => FlSpot(e.key.toDouble(), e.value.score))
                .toList(),
            isCurved: true,
            color: theme.colorScheme.primary,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                radius: 4,
                color: theme.colorScheme.primary,
                strokeWidth: 2,
                strokeColor: theme.scaffoldBackgroundColor,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.colorScheme.primary.withAlpha(50),
                  theme.colorScheme.primary.withAlpha(0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScatterChart(List<SubjectScore> scores, ThemeData theme) {
    return ScatterChart(
      ScatterChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: theme.dividerColor.withAlpha(30), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
              sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (val, meta) => Text(val.toInt().toString(),
                      style: TextStyle(
                          fontSize: 10,
                          color: theme.colorScheme.onSurface.withAlpha(100))))),
          bottomTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        scatterSpots: scores.asMap().entries.map((e) {
          return ScatterSpot(
            e.key.toDouble(),
            e.value.score,
            dotPainter: FlDotCirclePainter(
              radius: 8,
              color: theme.colorScheme.primary,
              strokeWidth: 0,
            ),
          );
        }).toList(),
      ),
    );
  }
}
