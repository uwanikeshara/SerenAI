import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;

import '../../../core/theme/app_theme.dart';
import '../../../core/database/local_db.dart';
import '../../../core/widgets/gradient_button.dart';

const _moods = [
  (emoji: '😤', tag: 'angry',    color: Color(0xFFFF6B6B)),
  (emoji: '😰', tag: 'anxious',  color: Color(0xFFCC55FF)),
  (emoji: '😔', tag: 'sad',      color: Color(0xFF5B9BFF)),
  (emoji: '😐', tag: 'neutral',  color: Color(0xFF8899B0)),
  (emoji: '😌', tag: 'calm',     color: Color(0xFF00D4B4)),
  (emoji: '😊', tag: 'happy',    color: Color(0xFFFFD93D)),
];

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  final _contentCtrl = TextEditingController();
  String? _selectedMood;
  bool _writing = false;
  bool _saving  = false;

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_contentCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);

    final id  = const Uuid().v4();
    final now = DateTime.now();
    final uid = Supabase.instance.client.auth.currentUser?.id;

    // Save locally
    final db = ref.read(localDbProvider);
    await db.insertJournalEntry(LocalJournalEntriesCompanion(
      id:        drift.Value(id),
      content:   drift.Value(_contentCtrl.text.trim()),
      moodTag:   drift.Value(_selectedMood ?? 'neutral'),
      createdAt: drift.Value(now),
    ));

    // Sync to Supabase
    if (uid != null) {
      try {
        await Supabase.instance.client.from('journal_entries').insert({
          'id':         id,
          'user_id':    uid,
          'content':    _contentCtrl.text.trim(),
          'mood_tag':   _selectedMood ?? 'neutral',
          'created_at': now.toIso8601String(),
        });
      } catch (_) {}
    }

    _contentCtrl.clear();
    if (mounted) {
      setState(() { _saving = false; _writing = false; _selectedMood = null; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final db      = ref.read(localDbProvider);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGrad),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Mood Journal',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                                
                              )),
                          Text(
                            DateFormat('EEEE, MMMM d').format(DateTime.now()),
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                              
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _writing = !_writing),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGrad,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          _writing ? Icons.close : Icons.edit_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Write panel
              if (_writing) ...[
                const SizedBox(height: 16),
                _buildWritePanel(),
              ],

              const SizedBox(height: 16),

              // Entries list
              Expanded(
                child: FutureBuilder<List<LocalJournalEntry>>(
                  future: db.getAllJournalEntries(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppTheme.primary),
                      );
                    }
                    final entries = snap.data!;
                    if (entries.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.menu_book_rounded,
                                color: AppTheme.textSecondary, size: 60),
                            SizedBox(height: 16),
                            Text('No journal entries yet',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  
                                )),
                            SizedBox(height: 8),
                            Text('Tap + to write your first entry',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  
                                )),
                          ],
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _JournalCard(entry: entries[i]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWritePanel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mood picker
          const Text('How are you feeling?',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                
              )),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _moods.map((m) {
              final selected = _selectedMood == m.tag;
              return GestureDetector(
                onTap: () => setState(() => _selectedMood = m.tag),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: selected ? m.color.withOpacity(0.2) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? m.color : Colors.transparent,
                    ),
                  ),
                  child: Text(m.emoji, style: const TextStyle(fontSize: 24)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // Text input
          TextField(
            controller: _contentCtrl,
            maxLines: 5,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              
            ),
            decoration: const InputDecoration(
              hintText: 'Write about how you\'re feeling...',
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 12),
          GradientButton(
            label: 'Save Entry',
            loading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

class _JournalCard extends StatelessWidget {
  final LocalJournalEntry entry;
  const _JournalCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final mood = _moods.firstWhere(
      (m) => m.tag == entry.moodTag,
      orElse: () => _moods[3],
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(mood.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                '${mood.tag[0].toUpperCase()}${mood.tag.substring(1)}',
                style: TextStyle(
                  color: mood.color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('MMM d, h:mm a').format(entry.createdAt.toLocal()),
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            entry.content,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              height: 1.5,
              
            ),
          ),
        ],
      ),
    );
  }
}
