import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../models/daily_emission.dart';
import '../widgets/glass_container.dart';
import '../widgets/calculator_form.dart';
import '../widgets/ai_insights_box.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  
  List<DailyEmission> _logs = [];
  CarbonStats _stats = CarbonStats.empty();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final logsData = await _apiService.fetchLogs();
      final statsData = await _apiService.fetchStats();
      setState(() {
        _logs = logsData;
        _stats = statsData;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showLogDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (BuildContext context) {
        return CalculatorForm(
          onLogAdded: (newLog) {
            _loadDashboardData();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Daily activity logged successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 950;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Title / Actions
                      _buildHeader(theme),
                      const SizedBox(height: 24),

                      // Metrics Cards Row
                      _buildMetricsGrid(isDesktop),
                      const SizedBox(height: 24),

                      // Main Content Area
                      if (isDesktop)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Section (Chart + Logs)
                            Expanded(
                              flex: 3,
                              child: Column(
                                children: [
                                  _buildChartCard(),
                                  const SizedBox(height: 24),
                                  _buildHistoryCard(),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            // Right Section (AI Insights)
                            Expanded(
                              flex: 2,
                              child: SizedBox(
                                height: 620, // Lock heights so it matches
                                child: AiInsightsBox(
                                  transportCo2: _logs.isEmpty ? 0.0 : _logs.last.transportEmissionsCo2Kg,
                                  electricityCo2: _logs.isEmpty ? 0.0 : _logs.last.electricityEmissionsCo2Kg,
                                  wasteCo2: _logs.isEmpty ? 0.0 : _logs.last.wasteEmissionsCo2Kg,
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            _buildChartCard(),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 380,
                              child: AiInsightsBox(
                                transportCo2: _logs.isEmpty ? 0.0 : _logs.last.transportEmissionsCo2Kg,
                                electricityCo2: _logs.isEmpty ? 0.0 : _logs.last.electricityEmissionsCo2Kg,
                                wasteCo2: _logs.isEmpty ? 0.0 : _logs.last.wasteEmissionsCo2Kg,
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildHistoryCard(),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 850) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.blur_on, color: Colors.greenAccent, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    'TERRAFLOW',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 3.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Carbon Footprint Awareness Platform',
                style: TextStyle(color: Colors.white30, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Semantics(
                label: 'Log Daily Activity Button',
                hint: 'Opens the daily activity carbon emission log form',
                button: true,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent[400],
                    foregroundColor: Colors.black,
                    minimumSize: const Size(180, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 8,
                    shadowColor: Colors.greenAccent.withOpacity(0.4),
                  ),
                  onPressed: _showLogDialog,
                  icon: const Icon(Icons.add, size: 20, color: Colors.black),
                  label: const Text(
                    'Log Daily Activity',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.blur_on, color: Colors.greenAccent, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      'TERRAFLOW',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 3.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Carbon Footprint Awareness Platform',
                  style: TextStyle(color: Colors.white30, fontSize: 13),
                ),
              ],
            ),
            Semantics(
              label: 'Log Daily Activity Button',
              hint: 'Opens the daily activity carbon emission log form',
              button: true,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent[400],
                  foregroundColor: Colors.black,
                  minimumSize: const Size(180, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 8,
                  shadowColor: Colors.greenAccent.withOpacity(0.4),
                ),
                onPressed: _showLogDialog,
                icon: const Icon(Icons.add, size: 20, color: Colors.black),
                label: const Text(
                  'Log Daily Activity',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricsGrid(bool isDesktop) {
    final double cardPadding = isDesktop ? 16 : 12;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isDesktop ? 4 : 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: isDesktop ? 1.6 : 1.3,
      children: [
        _buildMetricCard(
          title: 'Total Carbon',
          value: '${_stats.totalEmissionsCo2Kg.toStringAsFixed(1)} kg',
          subtitle: 'Cumulative CO2',
          icon: Icons.bubble_chart,
          accentColor: Colors.greenAccent,
        ),
        _buildMetricCard(
          title: 'Transit Footprint',
          value: '${_stats.transportTotalCo2Kg.toStringAsFixed(1)} kg',
          subtitle: 'Vehicular emissions',
          icon: Icons.directions_car,
          accentColor: Colors.lightBlueAccent,
        ),
        _buildMetricCard(
          title: 'Energy Index',
          value: '${_stats.electricityTotalCo2Kg.toStringAsFixed(1)} kg',
          subtitle: 'Home power CO2',
          icon: Icons.bolt,
          accentColor: Colors.amberAccent,
        ),
        _buildMetricCard(
          title: 'Waste Mitigated',
          value: '${_stats.wasteTotalCo2Kg.toStringAsFixed(1)} kg',
          subtitle: 'Landfill emission equivalents',
          icon: Icons.delete_outline,
          accentColor: Colors.cyanAccent,
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.all(16.0),
      borderColor: accentColor.withOpacity(0.12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Icon(icon, color: accentColor.withOpacity(0.8), size: 20),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white30, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard() {
    return GlassContainer(
      height: 320,
      borderColor: Colors.white.withOpacity(0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Emissions Timeline',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  _chartLegend('Transport', Colors.lightBlueAccent),
                  const SizedBox(width: 12),
                  _chartLegend('Electricity', Colors.amberAccent),
                  const SizedBox(width: 12),
                  _chartLegend('Waste', Colors.cyanAccent),
                ],
              )
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0, bottom: 8.0),
              child: _logs.isEmpty
                  ? const Center(child: Text('No historical logs found', style: TextStyle(color: Colors.white30)))
                  : LineChart(_getChartData()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }

  LineChartData _getChartData() {
    final List<FlSpot> totalSpots = [];
    final List<FlSpot> transportSpots = [];
    final List<FlSpot> electricitySpots = [];
    final List<FlSpot> wasteSpots = [];

    for (int i = 0; i < _logs.length; i++) {
      final log = _logs[i];
      final double x = i.toDouble();
      totalSpots.add(FlSpot(x, log.totalEmissionsCo2Kg));
      transportSpots.add(FlSpot(x, log.transportEmissionsCo2Kg));
      electricitySpots.add(FlSpot(x, log.electricityEmissionsCo2Kg));
      wasteSpots.add(FlSpot(x, log.wasteEmissionsCo2Kg));
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.white.withOpacity(0.04),
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            getTitlesWidget: (value, meta) {
              return Text(
                '${value.toInt()}k',
                style: const TextStyle(color: Colors.white30, fontSize: 10),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final int index = value.toInt();
              if (index >= 0 && index < _logs.length) {
                final date = _logs[index].date;
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    '${date.month}/${date.day}',
                    style: const TextStyle(color: Colors.white30, fontSize: 9),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: totalSpots,
          isCurved: true,
          color: Colors.greenAccent,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.greenAccent.withOpacity(0.06),
          ),
        ),
        LineChartBarData(
          spots: transportSpots,
          isCurved: true,
          color: Colors.lightBlueAccent.withOpacity(0.6),
          barWidth: 1.5,
          dotData: const FlDotData(show: false),
        ),
        LineChartBarData(
          spots: electricitySpots,
          isCurved: true,
          color: Colors.amberAccent.withOpacity(0.6),
          barWidth: 1.5,
          dotData: const FlDotData(show: false),
        ),
        LineChartBarData(
          spots: wasteSpots,
          isCurved: true,
          color: Colors.cyanAccent.withOpacity(0.6),
          barWidth: 1.5,
          dotData: const FlDotData(show: false),
        ),
      ],
    );
  }

  Widget _buildHistoryCard() {
    return GlassContainer(
      borderColor: Colors.white.withOpacity(0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Logs',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (_logs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Center(child: Text('No logged logs yet', style: TextStyle(color: Colors.white30))),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _logs.length > 5 ? 5 : _logs.length,
              separatorBuilder: (context, index) => const Divider(color: Colors.white12, height: 1),
              itemBuilder: (context, index) {
                // Return in reverse chronological order
                final log = _logs[_logs.length - 1 - index];
                final dateStr = '${log.date.year}-${log.date.month.toString().padLeft(2, '0')}-${log.date.day.toString().padLeft(2, '0')}';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dateStr,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Transit: ${log.transportVehicleType} (${log.transportDistanceKm.toStringAsFixed(0)}km) | Energy: ${log.electricityKwh}kWh',
                            style: const TextStyle(color: Colors.white30, fontSize: 11),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.greenAccent.withOpacity(0.2)),
                        ),
                        child: Text(
                          '${log.totalEmissionsCo2Kg.toStringAsFixed(2)} kg CO2',
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
