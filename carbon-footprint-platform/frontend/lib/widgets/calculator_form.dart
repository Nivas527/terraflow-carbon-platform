import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/daily_emission.dart';
import 'glass_container.dart';

class CalculatorForm extends StatefulWidget {
  final Function(DailyEmission) onLogAdded;

  const CalculatorForm({super.key, required this.onLogAdded});

  @override
  State<CalculatorForm> createState() => _CalculatorFormState();
}

class _CalculatorFormState extends State<CalculatorForm> {
  final PageController _pageController = PageController();
  final ApiService _apiService = ApiService();

  int _currentStep = 0;
  bool _isSaving = false;

  // Form State Values
  double _distance = 15.0;
  String _selectedVehicle = 'Car';
  String _selectedFuel = 'Petrol';

  double _electricityKwh = 10.0;

  double _wasteKg = 2.0;
  String _selectedWasteType = 'Mixed';
  double _recyclingRate = 30.0;

  final List<Map<String, dynamic>> _vehicles = [
    {
      'name': 'Car',
      'icon': Icons.directions_car,
      'fuels': ['Petrol', 'Diesel', 'Electric'],
    },
    {
      'name': 'Motorcycle',
      'icon': Icons.motorcycle,
      'fuels': ['Petrol', 'Electric'],
    },
    {
      'name': 'Bus',
      'icon': Icons.directions_bus,
      'fuels': ['Diesel', 'Electric', 'None'],
    },
    {
      'name': 'Train',
      'icon': Icons.train,
      'fuels': ['Electric', 'Diesel'],
    },
    {
      'name': 'Bicycle',
      'icon': Icons.pedal_bike,
      'fuels': ['None'],
    },
    {
      'name': 'Walking',
      'icon': Icons.directions_walk,
      'fuels': ['None'],
    },
  ];

  final List<String> _wasteTypes = ['Mixed', 'Organic', 'Plastic', 'Paper'];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevPage() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitForm() async {
    setState(() => _isSaving = true);
    try {
      final newLog = await _apiService.addLog(
        _selectedVehicle == 'Bicycle' || _selectedVehicle == 'Walking'
            ? 0.0
            : _distance,
        _selectedVehicle,
        _selectedFuel,
        _electricityKwh,
        _wasteKg,
        _selectedWasteType,
        _recyclingRate,
      );
      widget.onLogAdded(newLog);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save log: $e')));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: GlassContainer(
        width: 600,
        height: 580,
        borderColor: Colors.greenAccent.withOpacity(0.15),
        gradientColors: [
          Colors.grey[900]!.withOpacity(0.9),
          Colors.grey[800]!.withOpacity(0.85),
        ],
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Log Daily Activity',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.1,
                  ),
                ),
                Semantics(
                  label: 'Close activity logger',
                  button: true,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stepper indicator
            _buildStepperIndicator(),
            const SizedBox(height: 24),

            // Form Content Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildTransportStep(),
                  _buildElectricityStep(),
                  _buildWasteStep(),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStep > 0)
                  Semantics(
                    label: 'Back to previous step',
                    button: true,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        minimumSize: const Size(100, 48),
                      ),
                      onPressed: _prevPage,
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.greenAccent,
                      ),
                      label: const Text(
                        'Back',
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox.shrink(),

                _isSaving
                    ? const CircularProgressIndicator(color: Colors.greenAccent)
                    : Semantics(
                        label: _currentStep == 2
                            ? 'Calculate and log daily carbon footprint'
                            : 'Go to next step',
                        button: true,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.greenAccent[400],
                            foregroundColor: Colors.black,
                            minimumSize: const Size(160, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 8,
                            shadowColor: Colors.greenAccent.withOpacity(0.3),
                          ),
                          onPressed: _currentStep == 2
                              ? _submitForm
                              : _nextPage,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _currentStep == 2
                                    ? 'Calculate & Log'
                                    : 'Next Step',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _currentStep == 2
                                    ? Icons.check
                                    : Icons.arrow_forward,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperIndicator() {
    return Row(
      children: List.generate(3, (index) {
        final stepName = ['Transport', 'Electricity', 'Waste'][index];
        final isActive = index == _currentStep;
        final isCompleted = index < _currentStep;

        return Expanded(
          child: Row(
            children: [
              // Circle indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? Colors.greenAccent
                      : isActive
                      ? Colors.greenAccent.withOpacity(0.2)
                      : Colors.grey[800],
                  border: Border.all(
                    color: isCompleted || isActive
                        ? Colors.greenAccent
                        : Colors.grey[700]!,
                    width: 2,
                  ),
                  boxShadow: isActive || isCompleted
                      ? [
                          BoxShadow(
                            color: Colors.greenAccent.withOpacity(0.4),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, size: 16, color: Colors.black)
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isActive
                                ? Colors.greenAccent
                                : Colors.white60,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 8),
              // Step text labels (only if room allows or for desktop)
              Flexible(
                child: Text(
                  stepName,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    color: isActive
                        ? Colors.greenAccent
                        : isCompleted
                        ? Colors.white
                        : Colors.white30,
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              if (index < 2) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 2,
                    color: isCompleted ? Colors.greenAccent : Colors.grey[800],
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        );
      }),
    );
  }

  Widget _buildTransportStep() {
    final selectedVehicleData = _vehicles.firstWhere(
      (v) => v['name'] == _selectedVehicle,
    );
    final fuelOptions = selectedVehicleData['fuels'] as List<String>;

    // Ensure selected fuel matches options
    if (!fuelOptions.contains(_selectedFuel)) {
      _selectedFuel = fuelOptions.first;
    }

    final isZeroEmissions =
        _selectedVehicle == 'Bicycle' || _selectedVehicle == 'Walking';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mode of Transport',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          // Horizontal Vehicle selection grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.8,
            ),
            itemCount: _vehicles.length,
            itemBuilder: (context, index) {
              final vehicle = _vehicles[index];
              final isSelected = vehicle['name'] == _selectedVehicle;

              return Semantics(
                label: 'Select transit mode: ${vehicle['name']}',
                selected: isSelected,
                button: true,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedVehicle = vehicle['name'];
                      _selectedFuel = (vehicle['fuels'] as List<String>).first;
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.greenAccent.withOpacity(0.08)
                          : Colors.white.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? Colors.greenAccent
                            : Colors.white.withOpacity(0.08),
                        width: 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.greenAccent.withOpacity(0.1),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          vehicle['icon'],
                          color: isSelected
                              ? Colors.greenAccent
                              : Colors.white70,
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          vehicle['name'],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // Conditional inputs
          if (!isZeroEmissions) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Fuel Type',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedFuel,
                            dropdownColor: Colors.grey[900],
                            iconEnabledColor: Colors.greenAccent,
                            style: const TextStyle(color: Colors.white),
                            isExpanded: true,
                            items: fuelOptions.map((String fuel) {
                              return DropdownMenuItem<String>(
                                value: fuel,
                                child: Text(fuel),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedFuel = val);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Distance slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Daily Distance Traveled',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_distance.toStringAsFixed(0)} km',
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.greenAccent,
                inactiveTrackColor: Colors.grey[800],
                thumbColor: Colors.greenAccent,
                overlayColor: Colors.greenAccent.withOpacity(0.12),
                valueIndicatorColor: Colors.greenAccent,
              ),
              child: Semantics(
                label: 'Daily Distance Traveled Slider',
                value: '${_distance.toStringAsFixed(0)} kilometers',
                child: Slider(
                  value: _distance,
                  min: 0,
                  max: 150,
                  divisions: 150,
                  onChanged: (val) => setState(() => _distance = val),
                ),
              ),
            ),
          ] else ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: Column(
                  children: [
                    Icon(Icons.eco, color: Colors.greenAccent, size: 48),
                    SizedBox(height: 12),
                    Text(
                      'Zero Emissions Mode Selected!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Bicycling and walking do not consume fuel or emit CO2.',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildElectricityStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Home Electricity Consumption',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Input your average or exact household electricity usage for the day.',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 36),
          Center(
            child: Column(
              children: [
                Icon(Icons.bolt, color: Colors.amber[400], size: 56),
                const SizedBox(height: 16),
                Text(
                  '${_electricityKwh.toStringAsFixed(1)} kWh',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Estimated Footprint: ${(_electricityKwh * 0.40).toStringAsFixed(2)} kg CO2',
                  style: TextStyle(color: Colors.amber[400], fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.amber[400],
              inactiveTrackColor: Colors.grey[800],
              thumbColor: Colors.amber[400],
              overlayColor: Colors.amber[400]?.withOpacity(0.12),
            ),
            child: Semantics(
              label: 'Daily Electricity Consumption Slider',
              value: '${_electricityKwh.toStringAsFixed(1)} kilowatt hours',
              child: Slider(
                value: _electricityKwh,
                min: 0,
                max: 50,
                divisions: 100,
                onChanged: (val) => setState(() => _electricityKwh = val),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Eco Saver (0 kWh)',
                style: TextStyle(color: Colors.grey[500], fontSize: 11),
              ),
              Text(
                'High Demand (50 kWh)',
                style: TextStyle(color: Colors.grey[500], fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWasteStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Household Waste',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Estimated Daily Waste Weight',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              Text(
                '${_wasteKg.toStringAsFixed(1)} kg',
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.cyanAccent,
              inactiveTrackColor: Colors.grey[800],
              thumbColor: Colors.cyanAccent,
              overlayColor: Colors.cyanAccent.withOpacity(0.12),
            ),
            child: Semantics(
              label: 'Daily Waste Weight Slider',
              value: '${_wasteKg.toStringAsFixed(1)} kilograms',
              child: Slider(
                value: _wasteKg,
                min: 0,
                max: 10,
                divisions: 20,
                onChanged: (val) => setState(() => _wasteKg = val),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Waste Composition',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: _wasteTypes.map((type) {
              final isSelected = type == _selectedWasteType;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Text(type),
                    selected: isSelected,
                    selectedColor: Colors.cyanAccent.withOpacity(0.15),
                    backgroundColor: Colors.white.withOpacity(0.02),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.cyanAccent : Colors.white70,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isSelected
                            ? Colors.cyanAccent
                            : Colors.white.withOpacity(0.08),
                      ),
                    ),
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedWasteType = type);
                    },
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recycling Rate',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              Text(
                '${_recyclingRate.toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.cyanAccent,
              inactiveTrackColor: Colors.grey[800],
              thumbColor: Colors.cyanAccent,
              overlayColor: Colors.cyanAccent.withOpacity(0.12),
            ),
            child: Semantics(
              label: 'Waste Recycling Rate Slider',
              value: '${_recyclingRate.toStringAsFixed(0)} percent',
              child: Slider(
                value: _recyclingRate,
                min: 0,
                max: 100,
                divisions: 10,
                onChanged: (val) => setState(() => _recyclingRate = val),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
