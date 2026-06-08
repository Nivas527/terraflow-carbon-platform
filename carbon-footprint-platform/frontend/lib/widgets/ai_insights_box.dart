import 'dart:async';
import 'package:flutter/material.dart';
import 'glass_container.dart';

class AiInsightsBox extends StatefulWidget {
  final double transportCo2;
  final double electricityCo2;
  final double wasteCo2;

  const AiInsightsBox({
    super.key,
    required this.transportCo2,
    required this.electricityCo2,
    required this.wasteCo2,
  });

  @override
  State<AiInsightsBox> createState() => _AiInsightsBoxState();
}

class _AiInsightsBoxState extends State<AiInsightsBox> with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  Timer? _streamingTimer;
  String _displayedText = '';
  int _charIndex = 0;
  bool _isStreaming = false;

  late String _fullInsightText;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _generateInsightsText();
    _startStreaming();
  }

  @override
  void didUpdateWidget(covariant AiInsightsBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transportCo2 != widget.transportCo2 ||
        oldWidget.electricityCo2 != widget.electricityCo2 ||
        oldWidget.wasteCo2 != widget.wasteCo2) {
      _generateInsightsText();
      _startStreaming();
    }
  }

  void _generateInsightsText() {
    final double total = widget.transportCo2 + widget.electricityCo2 + widget.wasteCo2;

    _fullInsightText = 
        "🤖 **CARBON INSIGHTS ENGINE** [ONLINE]\n"
        "Analyzing daily logs... footprint totals **${total.toStringAsFixed(2)} kg CO2**.\n\n"
        "Here are three high-impact, personalized actions to lower your footprint:\n\n"
        "1. 🚗 **Transportation**: ${widget.transportCo2 > 3.0 
            ? 'Your transit emissions are significant (${widget.transportCo2.toStringAsFixed(1)} kg). Consider telecommuting tomorrow or combining errands to reduce travel by 10 km. Saving: **~1.8 kg CO2**.' 
            : 'Excellent job keeping transit emissions low! Walk or cycle for short distances to maintain your zero-emission streak.'}\n\n"
        "2. ⚡ **Electricity Usage**: ${widget.electricityCo2 > 4.0 
            ? 'Household electricity is your leading footprint segment today. Try adjusting your thermostat by 1°C and disconnecting standby appliances. Saving: **~0.6 kg CO2/day**.' 
            : 'Your household energy usage is very efficient. Keep it up by using natural daylight and LED lighting.'}\n\n"
        "3. ♻️ **Waste Management**: ${widget.wasteCo2 > 2.0 
            ? 'Your municipal waste emissions are active. Separating compostable organic waste from plastics will double your recycling factor. Saving: **~1.2 kg CO2/day**.' 
            : 'Your recycling and waste management levels are optimal. Consider buying items with less packaging to reduce bulk waste.'}";
  }

  void _startStreaming() {
    _streamingTimer?.cancel();
    setState(() {
      _displayedText = '';
      _charIndex = 0;
      _isStreaming = true;
    });

    _streamingTimer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      if (_charIndex < _fullInsightText.length) {
        setState(() {
          _displayedText += _fullInsightText[_charIndex];
          _charIndex++;
        });
      } else {
        setState(() => _isStreaming = false);
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    _streamingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.greenAccent.withOpacity(0.04 + (_glowController.value * 0.04)),
                blurRadius: 16 + (_glowController.value * 12),
                spreadRadius: 2,
              )
            ],
          ),
          child: child,
        );
      },
      child: GlassContainer(
        borderColor: Colors.greenAccent.withOpacity(0.2),
        gradientColors: [
          Colors.black.withOpacity(0.75),
          Colors.grey[900]!.withOpacity(0.65),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isStreaming ? Colors.greenAccent : Colors.white60,
                    boxShadow: _isStreaming
                        ? [
                            BoxShadow(
                              color: Colors.greenAccent,
                              blurRadius: 6,
                              spreadRadius: 1,
                            )
                          ]
                        : [],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'AI REDUCTION INSIGHTS',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                if (_isStreaming)
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.greenAccent,
                    ),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 16, color: Colors.white60),
                    onPressed: _startStreaming,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Regenerate Insights',
                  ),
              ],
            ),
            const Divider(color: Colors.white12, height: 24),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: RichText(
                  text: _parseMarkdown(_displayedText),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Simple parser to style basic markdown syntax like **bold**, headers, and code sections
  TextSpan _parseMarkdown(String text) {
    final List<TextSpan> spans = [];
    final List<String> lines = text.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.startsWith('🤖')) {
        spans.add(TextSpan(
          text: '$line\n',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            letterSpacing: 1.1,
            fontSize: 14,
          ),
        ));
        continue;
      }

      // Check for bullet items with emojis
      // Parse inline **bold** text
      spans.add(_parseInlineFormatting(line + (i < lines.length - 1 ? '\n' : '')));
    }

    return TextSpan(children: spans, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13, height: 1.5));
  }

  TextSpan _parseInlineFormatting(String line) {
    final List<TextSpan> segments = [];
    final RegExp boldRegex = RegExp(r'\*\*(.*?)\*\*');
    int start = 0;

    for (final Match match in boldRegex.allMatches(line)) {
      if (match.start > start) {
        segments.add(TextSpan(text: line.substring(start, match.start)));
      }
      segments.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(
          color: Colors.greenAccent,
          fontWeight: FontWeight.bold,
        ),
      ));
      start = match.end;
    }

    if (start < line.length) {
      segments.add(TextSpan(text: line.substring(start)));
    }

    return TextSpan(children: segments);
  }
}
