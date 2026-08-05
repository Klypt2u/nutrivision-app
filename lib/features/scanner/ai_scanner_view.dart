import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/food_item.dart';
import '../../core/models/meal_entry.dart';
import '../../core/providers/daily_log_provider.dart';
import '../../core/services/gemini_vision_service.dart';
import '../../core/services/open_food_facts_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/neon_button.dart';

enum _ScanMode { camera, barcode }

class AiScannerView extends ConsumerStatefulWidget {
  const AiScannerView({super.key});

  @override
  ConsumerState<AiScannerView> createState() => _AiScannerViewState();
}

class _AiScannerViewState extends ConsumerState<AiScannerView> {
  _ScanMode _mode = _ScanMode.camera;
  bool _analyzing = false;
  bool _busyLookup = false;
  AiMealAnalysis? _analysis;
  FoodItem? _barcodeResult;
  String _barcodeInput = '';
  String? _flash;

  final _gemini = GeminiVisionService();
  final _off = OpenFoodFactsService();

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _capture() async {
    if (_analyzing) return;
    setState(() {
      _analyzing = true;
      _analysis = null;
    });
    HapticFeedback.mediumImpact();
    try {
      // In a real device we'd capture via CameraController; in the simulator
      // (no camera) we trigger the mock analysis directly with no image data.
      final result = await _gemini.analyzeImage(
        base64Image: 'simulator_placeholder',
      );
      if (!mounted) return;
      setState(() {
        _analysis = result;
        _analyzing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _analyzing = false);
    }
  }

  Future<void> _lookupBarcode() async {
    final code = _barcodeInput.trim();
    if (code.isEmpty) return;
    setState(() {
      _busyLookup = true;
      _barcodeResult = null;
    });
    HapticFeedback.lightImpact();
    final res = await _off.lookupBarcode(code);
    if (!mounted) return;
    setState(() {
      _barcodeResult = res;
      _busyLookup = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.backgroundDeep),
      child: SafeArea(
        child: Column(
          children: [
            _topBar(),
            const SizedBox(height: 12),
            _modeToggle(),
            const SizedBox(height: 16),
            Expanded(child: _body()),
            _bottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40, height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.glassDark,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(CupertinoIcons.xmark, color: AppColors.textPrimary, size: 20),
            ),
          ),
          const Spacer(),
          Text('Scan Meal', style: AppText.h3),
          const Spacer(),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _flash = _flash == 'on' ? 'off' : (_flash == 'off' ? null : 'on'));
            },
            child: Container(
              width: 40, height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _flash != null ? AppColors.glassOverlay : AppColors.glassDark,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _flash == 'on' ? CupertinoIcons.bolt_fill : CupertinoIcons.bolt_slash,
                color: _flash == 'on' ? AppColors.neonAmber : AppColors.textPrimary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.glassDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: _ScanMode.values.map((m) {
          final sel = m == _mode;
          final label = m == _ScanMode.camera ? 'AI Camera' : 'Barcode';
          final icon = m == _ScanMode.camera ? CupertinoIcons.camera : CupertinoIcons.barcode;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _mode = m;
                  _analysis = null;
                  _barcodeResult = null;
                });
              },
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: sel ? AppColors.neonSweep : null,
                  color: sel ? null : Color(0x00000000),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: sel ? AppColors.textOnAccent : Color(0xFFFFFFFF), size: 16),
                    const SizedBox(width: 6),
                    Text(label, style: AppText.buttonSmall.copyWith(color: sel ? AppColors.textOnAccent : AppColors.textPrimary)),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _body() {
    if (_mode == _ScanMode.camera) {
      return _cameraBody();
    }
    return _barcodeBody();
  }

  // -------------------- AI Camera --------------------
  Widget _cameraBody() {
    return Stack(
      children: [
        // Camera preview / viewfinder
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Container(
              color: AppColors.backgroundDeep,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Stylized gradient "camera feed". A real device will replace
                  // this section with a CameraController preview.
                  Container(
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          Color(0xFF1A1A1F),
                          Color(0xFF08080B),
                        ],
                        radius: 1.0,
                      ),
                    ),
                  ),
                  // Subtle hex grid texture (decorative)
                  CustomPaint(painter: _GridPainter()),
                  Center(child: _viewfinderBrackets()),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.sparkles, color: Color(0xB3FFFFFF), size: 14),
                        const SizedBox(width: 6),
                        Text(
                          _analyzing ? 'Analyzing meal…' : 'Center your meal and tap to capture',
                          style: AppText.caption.copyWith(color: AppColors.textPrimary.withValues(alpha: 0.7)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_analysis != null)
          Positioned.fill(
            child: _AnalysisPanel(
              analysis: _analysis!,
              onAdd: _addAnalysisToLog,
              onClose: () => setState(() => _analysis = null),
            ),
          ),
      ],
    );
  }

  Widget _viewfinderBrackets() {
    return SizedBox(
      width: 270, height: 270,
      child: CustomPaint(painter: _BracketsPainter()),
    );
  }

  // -------------------- Barcode --------------------
  Widget _barcodeBody() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: AppColors.backgroundDeep,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.barcode, color: Color(0xFFFFFFFF), size: 36),
                      SizedBox(height: 8),
                      Text(
                        'Camera unavailable in simulator\nEnter a barcode below',
                        textAlign: TextAlign.center,                      style: TextStyle(
                            inherit: false,
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontFamily: '.SF Pro Text',
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            radius: 14,
            child: Row(
              children: [
                const Icon(CupertinoIcons.number, color: AppColors.textTertiary, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: CupertinoTextField(
                    placeholder: 'Enter barcode (e.g. 012000001017)',
                    placeholderStyle: AppText.body.copyWith(
                      color: AppColors.textTertiary, fontSize: 14,
                    ),
                    style: AppText.body.copyWith(color: AppColors.textPrimary, fontSize: 14),
                    decoration: const BoxDecoration(),
                    cursorColor: AppColors.neonLime,
                    keyboardType: TextInputType.number,
                    onChanged: (v) => setState(() => _barcodeInput = v),
                  ),
                ),
                GestureDetector(
                  onTap: _busyLookup ? null : _lookupBarcode,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: _busyLookup ? null : AppColors.neonSweep,
                      color: _busyLookup ? AppColors.glassDark : null,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _busyLookup ? '…' : 'Look up',
                      style: AppText.buttonSmall.copyWith(
                        color: _busyLookup ? AppColors.textTertiary : AppColors.textOnAccent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_barcodeResult != null) ...[
            const SizedBox(height: 16),
            Expanded(
              child: _BarcodeResultCard(
                food: _barcodeResult!,
                onAdd: _addBarcodeToLog,
              ),
            ),
          ] else
            const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            children: _sampleBarcodes.map((b) {
              final selected = _barcodeInput == b;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _barcodeInput = b);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.neonLime.withValues(alpha: 0.18) : AppColors.glassOverlaySoft,
                    border: Border.all(color: selected ? AppColors.neonLime : AppColors.borderSubtle),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    b,
                    style: AppText.caption.copyWith(
                      color: selected ? AppColors.neonLime : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _bottomActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        children: [
          if (_mode == _ScanMode.camera)
            _CaptureButton(
              loading: _analyzing,
              onTap: _capture,
            )
          else
            NeonButton(
              label: _busyLookup ? 'Looking up…' : 'Look up barcode',
              icon: CupertinoIcons.search,
              fullWidth: true,
              loading: _busyLookup,
              onPressed: _busyLookup ? null : _lookupBarcode,
            ),
          const SizedBox(height: 8),
          Text(
            _mode == _ScanMode.camera
                ? 'NutriVision AI analyzes your photo locally for privacy.'
                : 'Powered by Open Food Facts · millions of branded products',
            style: AppText.caption.copyWith(
              color: AppColors.textTertiary,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _addAnalysisToLog({required MealType type, required AiDetectedFood food, required MealType _}) async {
    // Add each detected food to today's log.
    setState(() => _analyzing = true);
    for (final d in _analysis!.foods) {
      await ref.read(dailyEntriesProvider.notifier).addFromFood(d.item, d.portionGrams, type);
    }
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _analyzing = false;
      _analysis = null;
    });
    Navigator.of(context).pop();
  }

  Future<void> _addBarcodeToLog({required MealType type, required double grams}) async {
    final food = _barcodeResult!;
    await ref.read(dailyEntriesProvider.notifier).addFromFood(food, grams, type);
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    setState(() => _barcodeResult = null);
    Navigator.of(context).pop();
  }
}



class _CaptureButton extends StatefulWidget {
  final bool loading;
  final VoidCallback onTap;
  const _CaptureButton({required this.loading, required this.onTap});
  @override
  State<_CaptureButton> createState() => _CaptureButtonState();
}

class _CaptureButtonState extends State<_CaptureButton> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 140),
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.loading ? null : widget.onTap,
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) async {
        await Future<void>.delayed(const Duration(milliseconds: 80));
        if (mounted) _ctrl.reverse();
      },
      onTapCancel: () => _ctrl.reverse(),
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final scale = 1 - _ctrl.value * 0.06;
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 96, height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.neonSweep,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonLime.withValues(alpha: 0.45),
                    blurRadius: 36,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.background,
                    border: Border.all(color: AppColors.textPrimary, width: 3),
                  ),
                  child: widget.loading
                      ? const Center(
                          child: CupertinoActivityIndicator(color: AppColors.neonLime, radius: 14),
                        )
                      : const Icon(CupertinoIcons.camera, color: AppColors.textPrimary, size: 26),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AnalysisPanel extends StatefulWidget {
  final AiMealAnalysis analysis;
  final Future<void> Function({required MealType type, required AiDetectedFood food, required MealType _}) onAdd;
  final VoidCallback onClose;
  const _AnalysisPanel({required this.analysis, required this.onAdd, required this.onClose});

  @override
  State<_AnalysisPanel> createState() => _AnalysisPanelState();
}

class _AnalysisPanelState extends State<_AnalysisPanel> {
  MealType _type = MealType.forHour(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final a = widget.analysis;
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            children: [
              const SizedBox(height: 6),
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(CupertinoIcons.sparkles, color: AppColors.neonLime, size: 18),
                  const SizedBox(width: 8),
                  Text('Recognized', style: AppText.h3),
                  const Spacer(),
                  IconButton(icon: const Icon(CupertinoIcons.xmark), onPressed: widget.onClose),
                ],
              ),
              const SizedBox(height: 6),
              Text(a.notes, style: AppText.bodySmall.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 14),
              ...a.foods.map((d) {
                final m = d.item.macrosFor(d.portionGrams);
                return GlassCard(
                  padding: const EdgeInsets.all(14),
                  radius: 18,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(d.item.emoji, style: const TextStyle(fontSize: 26)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(d.item.name, style: AppText.h4, maxLines: 1, overflow: TextOverflow.ellipsis),
                                if ((d.item.brand ?? '').isNotEmpty)
                                  Text(d.item.brand!, style: AppText.caption),
                              ],
                            ),
                          ),
                          if (d.item.confidence != null)
                            Text(
                              '${(d.item.confidence! * 100).toStringAsFixed(0)}%',
                              style: AppText.caption.copyWith(color: AppColors.neonCyan),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _MacroBubble(label: 'kcal',  value: m.kcal.round(),    color: AppColors.macroCalories),
                          const SizedBox(width: 6),
                          _MacroBubble(label: 'P',     value: m.protein.round(), color: AppColors.macroProtein),
                          const SizedBox(width: 6),
                          _MacroBubble(label: 'C',     value: m.carbs.round(),   color: AppColors.macroCarbs),
                          const SizedBox(width: 6),
                          _MacroBubble(label: 'F',     value: m.fat.round(),     color: AppColors.macroFat),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),
              _MealTypePickerInline(
                selected: _type,
                onChanged: (t) => setState(() => _type = t),
              ),
              const SizedBox(height: 14),
              NeonButton(
                label: 'Add ${a.foods.length} item${a.foods.length == 1 ? '' : 's'} to log',
                icon: CupertinoIcons.add,
                fullWidth: true,
                onPressed: () async {
                  // Add each detected food as a individual entry.
                  for (final d in a.foods) {
                    await _parentAdd(d, _type);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _parentAdd(AiDetectedFood d, MealType t) async {
    // Use the daily log provider directly.
    final container = ProviderScope.containerOf(context, listen: false);
    await container.read(dailyEntriesProvider.notifier).addFromFood(d.item, d.portionGrams, t);
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop();
  }
}

class _BarcodeResultCard extends StatefulWidget {
  final FoodItem food;
  final Future<void> Function({required MealType type, required double grams}) onAdd;
  const _BarcodeResultCard({required this.food, required this.onAdd});
  @override
  State<_BarcodeResultCard> createState() => _BarcodeResultCardState();
}

class _BarcodeResultCardState extends State<_BarcodeResultCard> {
  double _grams = 100;
  late MealType _type = MealType.forHour(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final m = widget.food.macrosFor(_grams);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassCard(
          padding: const EdgeInsets.all(14),
          radius: 18,
          child: Row(
            children: [
              Container(
                width: 56, height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: AppColors.macroSweep,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(widget.food.emoji, style: const TextStyle(fontSize: 26)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.food.name, style: AppText.h4, maxLines: 2, overflow: TextOverflow.ellipsis),
                    if ((widget.food.brand ?? '').isNotEmpty)
                      Text(widget.food.brand!, style: AppText.caption),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(14),
          radius: 18,
          child: Column(
            children: [
              Row(
                children: [
                  Text('Portion', style: AppText.label),
                  const Spacer(),
                  Text('${_grams.round()} g', style: AppText.metricSmall.copyWith(color: AppColors.neonLime)),
                ],
              ),
              CupertinoSlider(
                value: _grams.clamp(20, 800),
                min: 20, max: 800,
                activeColor: AppColors.neonLime,
                thumbColor: Color(0xFFFFFFFF),
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  setState(() => _grams = v);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(14),
          radius: 18,
          child: Row(
            children: [
              _MacroBubble(label: 'kcal', value: m.kcal.round(), color: AppColors.macroCalories),
              const SizedBox(width: 6),
              _MacroBubble(label: 'P',    value: m.protein.round(), color: AppColors.macroProtein),
              const SizedBox(width: 6),
              _MacroBubble(label: 'C',    value: m.carbs.round(), color: AppColors.macroCarbs),
              const SizedBox(width: 6),
              _MacroBubble(label: 'F',    value: m.fat.round(), color: AppColors.macroFat),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _MealTypePickerInline(
          selected: _type,
          onChanged: (t) => setState(() => _type = t),
        ),
        const SizedBox(height: 12),
        NeonButton(
          label: 'Add to log',
          icon: CupertinoIcons.add,
          fullWidth: true,
          onPressed: () async {
            final container = ProviderScope.containerOf(context, listen: false);
            await container.read(dailyEntriesProvider.notifier)
                .addFromFood(widget.food, _grams, _type);
            HapticFeedback.mediumImpact();
            if (!mounted) return;
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

class _MacroBubble extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _MacroBubble({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value.toString(), style: AppText.body.copyWith(color: color, fontWeight: FontWeight.w700)),
            Text(label, style: AppText.caption.copyWith(color: color, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _MealTypePickerInline extends StatelessWidget {
  final MealType selected;
  final ValueChanged<MealType> onChanged;
  const _MealTypePickerInline({required this.selected, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.glassDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: MealType.values.map((t) {
          final isSel = t == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(t);
              },
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSel ? AppColors.neonSweep : null,
                  color: isSel ? null : Color(0x00000000),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Center(
                  child: Text(t.emoji, style: const TextStyle(fontSize: 18)),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// -------------------- Decorative painters --------------------

class _BracketsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = AppColors.neonLime.withValues(alpha: 0.6);
    final r = 24.0;
    final cl = size.width, ct = size.height;

    // Corners
    void draw(double x, double y, double dx, double dy) {
      canvas.drawLine(Offset(x, y), Offset(x + dx, y), paint);
      canvas.drawLine(Offset(x, y), Offset(x, y + dy), paint);
    }
    draw(0, 0, r, r);
    draw(cl, 0, -r, r);
    draw(0, ct, r, -r);
    draw(cl, ct, -r, -r);

    // Pulse ring
    final pulsePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = AppColors.neonCyan.withValues(alpha: 0.35);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, cl, ct),
      pulsePaint,
    );
  }

  @override
  bool shouldRepaint(_BracketsPainter old) => false;
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.borderSubtle.withValues(alpha: 0.4)
      ..strokeWidth = 0.7;
    const step = 24.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}

class IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  const IconButton({super.key, required this.icon, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minSize: 0,
      onPressed: onPressed,
      child: Container(
        width: 32, height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.glassDark,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 16),
      ),
    );
  }
}

const _sampleBarcodes = <String>[
  '012000001017', '028400064057', '858041004018', '040000485101',
];
