import 'package:flutter/material.dart';

class AlarmEditorResult {
  const AlarmEditorResult({
    required this.title,
    required this.scheduledFor,
    this.message,
    this.repeatRule,
  });

  final String title;
  final String? message;
  final DateTime scheduledFor;
  final String? repeatRule;
}

class AlarmEditorSheet extends StatefulWidget {
  const AlarmEditorSheet({
    super.key,
    this.initialTitle,
    this.initialMessage,
    this.initialDateTime,
  });

  final String? initialTitle;
  final String? initialMessage;
  final DateTime? initialDateTime;

  @override
  State<AlarmEditorSheet> createState() => _AlarmEditorSheetState();
}

class _AlarmEditorSheetState extends State<AlarmEditorSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _msgCtrl;
  DateTime _when = DateTime.now().add(const Duration(minutes: 5));
  String _repeat = 'none';

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initialTitle ?? '');
    _msgCtrl = TextEditingController(text: widget.initialMessage ?? '');
    if (widget.initialDateTime != null) _when = widget.initialDateTime!;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isValid = _titleCtrl.text.trim().isNotEmpty;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Nouvelle alarme',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Titre',
                hintText: 'Ex: Réunion client',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _msgCtrl,
              decoration: const InputDecoration(
                labelText: 'Message (optionnel)',
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickDateTime,
              icon: const Icon(Icons.schedule_rounded),
              label: Text(
                '${_when.day.toString().padLeft(2, '0')}/${_when.month.toString().padLeft(2, '0')} '
                '${_when.hour.toString().padLeft(2, '0')}:${_when.minute.toString().padLeft(2, '0')}',
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _repeat,
              decoration: const InputDecoration(labelText: 'Répétition'),
              items: const [
                DropdownMenuItem(value: 'none', child: Text('Aucune')),
                DropdownMenuItem(value: 'daily', child: Text('Chaque jour')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _repeat = v);
              },
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: !isValid
                  ? null
                  : () {
                      Navigator.of(context).pop(
                        AlarmEditorResult(
                          title: _titleCtrl.text.trim(),
                          message: _msgCtrl.text.trim().isEmpty
                              ? null
                              : _msgCtrl.text.trim(),
                          scheduledFor: _when,
                          repeatRule: _repeat == 'none' ? null : _repeat,
                        ),
                      );
                    },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDate: _when,
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_when),
    );
    if (t == null || !mounted) return;
    setState(() {
      _when = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    });
  }
}

