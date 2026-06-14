import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_utils.dart';
import '../../../models/workout_log_model.dart';
import '../../../providers/app_providers.dart';
import '../../../widgets/common/app_button.dart';
import '../providers/session_provider.dart';

class SessionScreen extends ConsumerStatefulWidget {
  final String sessionName;
  const SessionScreen({super.key, required this.sessionName});

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sessionProvider(widget.sessionName));
    final settings = ref.watch(appSettingsProvider);
    final isAr = settings.language == 'ar';
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) _confirmExit(context, isAr);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.sessionName,
              style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _confirmExit(context, isAr),
          ),
          actions: [
            // Timer indicator
            if (state.restTimerActive)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    AppUtils.formatDuration(state.restTimeRemaining),
                    style: TextStyle(
                        fontFamily: 'Cairo', fontWeight: FontWeight.w800,
                        fontSize: 16, color: theme.colorScheme.primary),
                  ),
                ),
              ),
          ],
        ),
        body: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : state.isComplete
                ? _SessionDoneView(sessionName: widget.sessionName, isAr: isAr, state: state)
                : _SessionBodyView(
                    sessionName: widget.sessionName,
                    state: state,
                    isAr: isAr,
                    settings: settings,
                  ),
      ),
    );
  }

  void _confirmExit(BuildContext ctx, bool isAr) {
    showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        title: Text(isAr ? 'خروج من الجلسة؟' : 'Exit Session?'),
        content: Text(isAr
            ? 'سيتم حفظ التقدم المكتمل. هل تريد المتابعة؟'
            : 'Completed progress will be saved. Continue?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: Text(isAr ? 'لا' : 'No')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dCtx);
              ref.read(sessionProvider(widget.sessionName).notifier).saveAndExit();
              if (mounted) Navigator.pop(ctx);
            },
            child: Text(isAr ? 'خروج وحفظ' : 'Exit & Save'),
          ),
        ],
      ),
    );
  }
}

// ── Session Body ──────────────────────────────────────
class _SessionBodyView extends ConsumerWidget {
  final String sessionName;
  final SessionState state;
  final bool isAr;
  final AppSettings settings;

  const _SessionBodyView({
    required this.sessionName,
    required this.state,
    required this.isAr,
    required this.settings,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(sessionProvider(sessionName).notifier);

    if (!state.warmupDone) {
      return _WarmupView(isAr: isAr, onDone: notifier.completeWarmup);
    }

    final exercises = state.exercises;
    if (exercises.isEmpty) {
      return Center(child: Text(isAr ? 'لا توجد تمارين' : 'No exercises'));
    }

    final currentEx = exercises[state.currentExIndex];
    final prevLog = state.prevLogs[currentEx.name];

    return Column(
      children: [
        // ── Progress indicator ──────────────────────
        LinearProgressIndicator(
          value: (state.currentExIndex) / exercises.length,
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Exercise header ─────────────────
                _ExerciseHeader(exercise: currentEx, isAr: isAr, state: state, notifier: notifier),
                const SizedBox(height: 12),

                // ── Previous values ──────────────────
                if (settings.showOldValues && prevLog != null)
                  _PrevValuesCard(prevLog: prevLog, isAr: isAr),

                // ── Sets input ───────────────────────
                _SetsInput(
                  exercise: currentEx,
                  state: state,
                  notifier: notifier,
                  isAr: isAr,
                  settings: settings,
                ),
                const SizedBox(height: 12),

                // ── Rest timer ───────────────────────
                _RestTimerCard(state: state, notifier: notifier, isAr: isAr),
                const SizedBox(height: 12),

                // ── Alt swap ────────────────────────
                if (currentEx.alt1 != null || currentEx.alt2 != null)
                  _AltSwapCard(exercise: currentEx, state: state, notifier: notifier, isAr: isAr),
                const SizedBox(height: 12),

                // ── Navigation ───────────────────────
                Row(
                  children: [
                    if (state.currentExIndex > 0)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: notifier.prevExercise,
                          icon: const Icon(Icons.arrow_back_ios, size: 16),
                          label: Text(isAr ? 'السابق' : 'Prev'),
                        ),
                      ),
                    if (state.currentExIndex > 0) const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (state.currentExIndex >= exercises.length - 1) {
                            notifier.finishSession();
                          } else {
                            notifier.nextExercise();
                          }
                        },
                        icon: Icon(
                          state.currentExIndex >= exercises.length - 1
                              ? Icons.check_circle
                              : Icons.arrow_forward_ios,
                          size: 16,
                        ),
                        label: Text(
                          state.currentExIndex >= exercises.length - 1
                              ? (isAr ? 'إنهاء الجلسة 🎉' : 'Finish Session 🎉')
                              : (isAr ? 'التمرين التالي' : 'Next Exercise'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Warmup View ───────────────────────────────────────
class _WarmupView extends StatelessWidget {
  final bool isAr;
  final VoidCallback onDone;

  const _WarmupView({required this.isAr, required this.onDone});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.whatshot, color: Colors.orange, size: 22),
                      const SizedBox(width: 8),
                      Text(isAr ? 'بروتوكول الإحماء' : 'Warmup Protocol',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700,
                              fontFamily: 'Cairo')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...kWarmupItems.map((w) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Icon(Icons.fitness_center,
                                    size: 16, color: theme.colorScheme.primary),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(w.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Cairo')),
                                  Text('${w.reps}  |  ${isAr ? w.note : w.note}',
                                      style: const TextStyle(
                                          fontSize: 11, color: Colors.grey,
                                          fontFamily: 'Cairo')),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: isAr ? 'انتهيت من الإحماء ✓ ابدأ التمرين' : 'Warmup Done ✓ Start Workout',
            icon: Icons.play_arrow,
            onPressed: onDone,
          ),
        ],
      ),
    );
  }
}

// ── Exercise Header ───────────────────────────────────
class _ExerciseHeader extends StatelessWidget {
  final ExerciseDef exercise;
  final bool isAr;
  final SessionState state;
  final SessionNotifier notifier;

  const _ExerciseHeader({
    required this.exercise,
    required this.isAr,
    required this.state,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = state.swaps[exercise.name] ?? exercise.name;
    final isSwapped = state.swaps.containsKey(exercise.name);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: exercise.primary
                        ? theme.colorScheme.primary.withOpacity(0.15)
                        : Colors.grey.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    exercise.primary
                        ? (isAr ? 'أساسي' : 'Primary')
                        : (isAr ? 'ثانوي' : 'Secondary'),
                    style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: exercise.primary
                            ? theme.colorScheme.primary
                            : Colors.grey,
                        fontFamily: 'Cairo'),
                  ),
                ),
                const Spacer(),
                Text(
                  '${state.currentExIndex + 1} / ${state.exercises.length}',
                  style: const TextStyle(
                      fontSize: 12, color: Colors.grey, fontFamily: 'Cairo'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              displayName,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (isSwapped)
              Text(
                '↔ ${isAr ? "بديل عن" : "Alt for"}: ${exercise.name}',
                style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Cairo'),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                _Chip(icon: Icons.repeat, label: '${exercise.sets} sets'),
                const SizedBox(width: 6),
                _Chip(icon: Icons.looks_one, label: '${exercise.reps} reps'),
                const SizedBox(width: 6),
                _Chip(icon: Icons.timer, label: '${exercise.rest} min'),
              ],
            ),
            if (exercise.muscle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('💪 ${exercise.muscle}',
                  style: const TextStyle(
                      fontSize: 12, color: Colors.grey, fontFamily: 'Cairo')),
            ],
            if (exercise.note != null && exercise.note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡 ', style: TextStyle(fontSize: 12)),
                    Expanded(
                      child: Text(exercise.note!,
                          style: const TextStyle(
                              fontSize: 12, fontFamily: 'Cairo', color: Colors.amber)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey),
          const SizedBox(width: 3),
          Text(label,
              style: const TextStyle(fontSize: 11, fontFamily: 'Cairo', color: Colors.grey)),
        ],
      ),
    );
  }
}

// ── Previous Values Card ──────────────────────────────
class _PrevValuesCard extends StatelessWidget {
  final ExerciseLog prevLog;
  final bool isAr;
  const _PrevValuesCard({required this.prevLog, required this.isAr});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isAr ? '📅 الجلسة السابقة:' : '📅 Previous Session:',
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, fontFamily: 'Cairo',
                  color: Colors.blue)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: prevLog.sets.map((s) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${s.weight}kg × ${s.reps}',
                    style: const TextStyle(
                        fontSize: 12, fontFamily: 'Cairo', color: Colors.blue),
                  ),
                )).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Sets Input ────────────────────────────────────────
class _SetsInput extends ConsumerWidget {
  final ExerciseDef exercise;
  final SessionState state;
  final SessionNotifier notifier;
  final bool isAr;
  final AppSettings settings;

  const _SetsInput({
    required this.exercise,
    required this.state,
    required this.notifier,
    required this.isAr,
    required this.settings,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exName = state.swaps[exercise.name] ?? exercise.name;
    final currentSets = state.currentSets[exName] ?? [];
    final theme = Theme.of(context);

    // Ensure sets list has enough entries
    final expectedSets = exercise.sets;
    final sets = List.generate(expectedSets, (i) {
      if (i < currentSets.length) return currentSets[i];
      return ExerciseSet(weight: 0, reps: exercise.repsMin);
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isAr ? 'المجاميع' : 'Sets',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'Cairo')),
            const SizedBox(height: 10),
            // ── Warmup sets ──────────────────────
            if (exercise.warmupSetsCount > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '🔥 ${exercise.warmupSetsCount} ${isAr ? "مجموعة إحماء" : "warmup set(s)"}',
                  style: const TextStyle(
                      fontSize: 12, color: Colors.orange, fontFamily: 'Cairo'),
                ),
              ),
            // ── Working sets ─────────────────────
            ...List.generate(sets.length, (i) {
              final s = sets[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _SetRow(
                  index: i,
                  set: s,
                  isAr: isAr,
                  settings: settings,
                  onWeightChanged: (w) => notifier.updateSet(exName, i, weight: w),
                  onRepsChanged: (r) => notifier.updateSet(exName, i, reps: r),
                  onRPEChanged: (rpe) => notifier.updateSet(exName, i, rpe: rpe),
                ),
              );
            }),
            // ── Epley / Volume ───────────────────
            if ((settings.showEpley || settings.showVolume) && currentSets.isNotEmpty)
              _ExStatsRow(sets: sets, settings: settings, isAr: isAr),
          ],
        ),
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  final int index;
  final ExerciseSet set;
  final bool isAr;
  final AppSettings settings;
  final ValueChanged<double> onWeightChanged;
  final ValueChanged<int> onRepsChanged;
  final ValueChanged<double>? onRPEChanged;

  const _SetRow({
    required this.index,
    required this.set,
    required this.isAr,
    required this.settings,
    required this.onWeightChanged,
    required this.onRepsChanged,
    this.onRPEChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text('${index + 1}',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary, fontFamily: 'Cairo')),
          ),
        ),
        const SizedBox(width: 8),
        // Weight
        Expanded(
          child: _NumericField(
            value: set.weight,
            label: isAr ? 'كغ' : 'kg',
            step: 2.5,
            decimals: 1,
            onChanged: onWeightChanged,
          ),
        ),
        const SizedBox(width: 8),
        // Reps
        Expanded(
          child: _NumericField(
            value: set.reps.toDouble(),
            label: isAr ? 'عدات' : 'reps',
            step: 1,
            decimals: 0,
            onChanged: (v) => onRepsChanged(v.toInt()),
          ),
        ),
        if (settings.showRPE) ...[
          const SizedBox(width: 8),
          Expanded(
            child: _NumericField(
              value: set.rpe ?? 0,
              label: 'RPE',
              step: 0.5,
              decimals: 1,
              min: 0,
              max: 10,
              onChanged: (v) => onRPEChanged?.call(v),
            ),
          ),
        ],
      ],
    );
  }
}

class _NumericField extends StatefulWidget {
  final double value;
  final String label;
  final double step;
  final int decimals;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _NumericField({
    required this.value,
    required this.label,
    required this.step,
    required this.decimals,
    this.min = 0,
    this.max = 9999,
    required this.onChanged,
  });

  @override
  State<_NumericField> createState() => _NumericFieldState();
}

class _NumericFieldState extends State<_NumericField> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
        text: widget.decimals == 0
            ? widget.value.toInt().toString()
            : widget.value.toStringAsFixed(widget.decimals));
  }

  @override
  void didUpdateWidget(covariant _NumericField old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      final newText = widget.decimals == 0
          ? widget.value.toInt().toString()
          : widget.value.toStringAsFixed(widget.decimals);
      if (_ctrl.text != newText) _ctrl.text = newText;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(widget.label,
            style: const TextStyle(
                fontSize: 10, color: Colors.grey, fontFamily: 'Cairo')),
        const SizedBox(height: 3),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Cairo'),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  isDense: true,
                ),
                onChanged: (v) {
                  final parsed = double.tryParse(v);
                  if (parsed != null) {
                    widget.onChanged(parsed.clamp(widget.min, widget.max));
                  }
                },
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StepBtn(Icons.remove, () {
              final v = (widget.value - widget.step).clamp(widget.min, widget.max);
              widget.onChanged(v);
            }),
            const SizedBox(width: 4),
            _StepBtn(Icons.add, () {
              final v = (widget.value + widget.step).clamp(widget.min, widget.max);
              widget.onChanged(v);
            }),
          ],
        ),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepBtn(this.icon, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 14),
      ),
    );
  }
}

class _ExStatsRow extends StatelessWidget {
  final List<ExerciseSet> sets;
  final AppSettings settings;
  final bool isAr;
  const _ExStatsRow({required this.sets, required this.settings, required this.isAr});

  @override
  Widget build(BuildContext context) {
    double maxEpley = 0;
    double totalVolume = 0;
    for (final s in sets) {
      if (s.weight > 0 && s.reps > 0) {
        final ep = AppUtils.epley(s.weight, s.reps);
        if (ep > maxEpley) maxEpley = ep;
        totalVolume += s.weight * s.reps;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          if (settings.showEpley && maxEpley > 0)
            Expanded(
              child: _StatPill(
                label: isAr ? '1RM تقديري' : 'Est. 1RM',
                value: '${maxEpley.toStringAsFixed(1)} kg',
                color: AppColors.accent,
              ),
            ),
          if (settings.showVolume && totalVolume > 0) ...[
            const SizedBox(width: 8),
            Expanded(
              child: _StatPill(
                label: isAr ? 'الحجم' : 'Volume',
                value: '${totalVolume.toStringAsFixed(0)} kg',
                color: AppColors.ok,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatPill({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w800, color: color,
                  fontSize: 13, fontFamily: 'Cairo')),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: Colors.grey, fontFamily: 'Cairo')),
        ],
      ),
    );
  }
}

// ── Rest Timer Card ───────────────────────────────────
class _RestTimerCard extends StatelessWidget {
  final SessionState state;
  final SessionNotifier notifier;
  final bool isAr;
  const _RestTimerCard({required this.state, required this.notifier, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.timer, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(isAr ? 'وقت الراحة' : 'Rest Timer',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'Cairo')),
                const Spacer(),
                Text(
                  AppUtils.formatDuration(state.restTimerActive
                      ? state.restTimeRemaining
                      : state.restTimerDuration),
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800,
                      color: state.restTimerActive
                          ? theme.colorScheme.primary
                          : Colors.grey,
                      fontFamily: 'Cairo'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: state.restTimerActive
                        ? notifier.stopRestTimer
                        : notifier.startRestTimer,
                    icon: Icon(state.restTimerActive ? Icons.stop : Icons.play_arrow,
                        size: 18),
                    label: Text(
                      state.restTimerActive
                          ? (isAr ? 'إيقاف' : 'Stop')
                          : (isAr ? 'بدء الراحة' : 'Start Rest'),
                      style: const TextStyle(fontFamily: 'Cairo'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: notifier.resetRestTimer,
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: isAr ? 'إعادة' : 'Reset',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Alt Swap Card ─────────────────────────────────────
class _AltSwapCard extends StatelessWidget {
  final ExerciseDef exercise;
  final SessionState state;
  final SessionNotifier notifier;
  final bool isAr;
  const _AltSwapCard({
    required this.exercise,
    required this.state,
    required this.notifier,
    required this.isAr,
  });

  @override
  Widget build(BuildContext context) {
    final alts = [
      if (exercise.alt1 != null && exercise.alt1!.isNotEmpty) exercise.alt1!,
      if (exercise.alt2 != null && exercise.alt2!.isNotEmpty) exercise.alt2!,
    ];
    if (alts.isEmpty) return const SizedBox.shrink();

    final currentSwap = state.swaps[exercise.name];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.swap_horiz, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Text(isAr ? 'تمارين بديلة' : 'Alternative Exercises',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'Cairo')),
              ],
            ),
            const SizedBox(height: 8),
            if (currentSwap != null)
              ListTile(
                dense: true,
                leading: const Icon(Icons.check_circle, color: AppColors.ok, size: 18),
                title: Text(currentSwap,
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                trailing: TextButton(
                  onPressed: () => notifier.removeSwap(exercise.name),
                  child: Text(isAr ? 'إلغاء' : 'Undo'),
                ),
              )
            else
              ...alts.map((alt) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.sync_alt, size: 18, color: Colors.grey),
                    title: Text(alt,
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                    trailing: TextButton(
                      onPressed: () => notifier.setSwap(exercise.name, alt),
                      child: Text(isAr ? 'استخدام' : 'Use'),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

// ── Session Done View ─────────────────────────────────
class _SessionDoneView extends ConsumerWidget {
  final String sessionName;
  final bool isAr;
  final SessionState state;
  const _SessionDoneView({
    required this.sessionName,
    required this.isAr,
    required this.state,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              isAr ? 'أحسنت! انتهت الجلسة' : 'Well Done! Session Complete',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              sessionName,
              style: TextStyle(color: theme.colorScheme.primary, fontFamily: 'Cairo',
                  fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 24),
            // ── New PRs ────────────────────────────
            if (state.newPRs.isNotEmpty) ...[
              Card(
                color: AppColors.evalS1.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      const Text('🏆 أرقام قياسية جديدة!',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontFamily: 'Cairo',
                              fontSize: 14, color: AppColors.evalS1)),
                      const SizedBox(height: 8),
                      ...state.newPRs.map((pr) => Text(
                            '${pr.exerciseName}: ${pr.weight}kg × ${pr.reps} (${pr.epley.toStringAsFixed(1)} 1RM)',
                            style: const TextStyle(
                                fontFamily: 'Cairo', fontSize: 12,
                                color: AppColors.evalS1),
                          )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            AppButton(
              label: isAr ? 'العودة للرئيسية' : 'Back to Home',
              icon: Icons.home,
              onPressed: () {
                ref.read(sessionProvider(sessionName).notifier).saveAndExit();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
