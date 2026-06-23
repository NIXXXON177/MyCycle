import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:florea/core/enums/energy_level.dart';
import 'package:florea/core/enums/intimacy_type.dart';
import 'package:florea/core/enums/mood_level.dart';
import 'package:florea/core/enums/pain_level.dart';
import 'package:florea/core/enums/pain_location.dart';
import 'package:florea/core/enums/pms_symptom.dart';
import 'package:florea/core/providers/app_providers.dart';
import 'package:florea/core/utils/date_utils.dart';
import 'package:florea/features/wellbeing/domain/entities/wellbeing_entry.dart';
import 'package:florea/shared/widgets/app_card.dart';

/// Экран отметки ежедневного самочувствия.
class WellbeingScreen extends ConsumerStatefulWidget {
  const WellbeingScreen({super.key, this.initialDate});

  /// Дата, открываемая по умолчанию (например, из календаря).
  final DateTime? initialDate;

  @override
  ConsumerState<WellbeingScreen> createState() => _WellbeingScreenState();
}

class _WellbeingScreenState extends ConsumerState<WellbeingScreen> {
  late DateTime _selectedDate;
  MoodLevel _mood = MoodLevel.normal;
  EnergyLevel _energy = EnergyLevel.medium;
  PainLevel _pain = PainLevel.none;
  IntimacyType _intimacy = IntimacyType.none;
  final Set<PainLocation> _painLocations = {};
  final Set<PmsSymptom> _pmsSymptoms = {};
  final _noteController = TextEditingController();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _loadEntry();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadEntry() async {
    final entry = await ref
        .read(wellbeingRepositoryProvider)
        .getByDate(_selectedDate);
    if (!mounted) return;
    setState(() {
      if (entry != null) {
        _mood = entry.mood;
        _energy = entry.energy;
        _pain = entry.pain;
        _painLocations
          ..clear()
          ..addAll(entry.painLocations);
        _intimacy = entry.intimacy;
        _pmsSymptoms
          ..clear()
          ..addAll(entry.pmsSymptoms);
        _noteController.text = entry.note ?? '';
      } else {
        _mood = MoodLevel.normal;
        _energy = EnergyLevel.medium;
        _pain = PainLevel.none;
        _intimacy = IntimacyType.none;
        _painLocations.clear();
        _pmsSymptoms.clear();
        _noteController.clear();
      }
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Самочувствие'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                locale: const Locale('ru'),
              );
              if (picked != null) {
                setState(() {
                  _selectedDate = picked;
                  _loaded = false;
                });
                _loadEntry();
              }
            },
          ),
        ],
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Text(
              AppDateUtils.formatDate(_selectedDate),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 16),
          const SectionTitle('Настроение'),
          _buildSelector(
            items: MoodLevel.values,
            selected: _mood,
            label: (m) => '${m.emoji} ${m.label}',
            onSelected: (m) => setState(() => _mood = m),
          ),
          const SectionTitle('Энергия'),
          _buildSelector(
            items: EnergyLevel.values,
            selected: _energy,
            label: (e) => '${e.emoji} ${e.label}',
            onSelected: (e) => setState(() => _energy = e),
          ),
          const SectionTitle('Боль'),
          _buildSelector(
            items: PainLevel.values,
            selected: _pain,
            label: (p) => '${p.emoji} ${p.label}',
            onSelected: (p) => setState(() {
              _pain = p;
              if (p == PainLevel.none) _painLocations.clear();
            }),
          ),
          if (_pain != PainLevel.none) ...[
            const SectionTitle('Локализация боли'),
            Wrap(
              spacing: 8,
              children: PainLocation.values.map((loc) {
                final selected = _painLocations.contains(loc);
                return FilterChip(
                  label: Text('${loc.emoji} ${loc.label}'),
                  selected: selected,
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        _painLocations.add(loc);
                      } else {
                        _painLocations.remove(loc);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
          const SectionTitle('Симптомы ПМС'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PmsSymptom.values.map((symptom) {
              final selected = _pmsSymptoms.contains(symptom);
              return FilterChip(
                label: Text('${symptom.emoji} ${symptom.label}'),
                selected: selected,
                onSelected: (value) {
                  setState(() {
                    if (value) {
                      _pmsSymptoms.add(symptom);
                    } else {
                      _pmsSymptoms.remove(symptom);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SectionTitle('Близость'),
          _buildSelector(
            items: IntimacyType.loggable,
            selected: _intimacy,
            label: (i) => i == IntimacyType.none
                ? i.label
                : '${i.emoji} ${i.label}',
            onSelected: (i) => setState(() => _intimacy = i),
          ),
          const SectionTitle('Заметка'),
          TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Как прошёл день...',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _save,
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  Widget _buildSelector<T>({
    required List<T> items,
    required T selected,
    required String Function(T) label,
    required ValueChanged<T> onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final isSelected = item == selected;
        return ChoiceChip(
          label: Text(label(item)),
          selected: isSelected,
          onSelected: (_) => onSelected(item),
        );
      }).toList(),
    );
  }

  Future<void> _save() async {
    final existing = await ref
        .read(wellbeingRepositoryProvider)
        .getByDate(_selectedDate);

    final entry = WellbeingEntry(
      id: existing?.id ?? '',
      date: _selectedDate,
      mood: _mood,
      energy: _energy,
      pain: _pain,
      painLocations: _painLocations.toList(),
      pmsSymptoms: _pmsSymptoms.toList(),
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      intimacy: _intimacy,
    );

    await ref.read(wellbeingRepositoryProvider).saveForDate(
          date: _selectedDate,
          existingId: existing?.id,
          entry: entry,
        );

    invalidateAllData(ref);
    ref.invalidate(wellbeingByDateProvider(_selectedDate));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Самочувствие сохранено')),
      );
    }
  }
}
