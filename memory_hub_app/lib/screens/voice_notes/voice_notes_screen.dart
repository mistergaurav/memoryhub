import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../design_system/design_system.dart';

class VoiceNotesScreen extends StatefulWidget {
  const VoiceNotesScreen({super.key});

  @override
  State<VoiceNotesScreen> createState() => _VoiceNotesScreenState();
}

class _VoiceNotesScreenState extends State<VoiceNotesScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _voiceNotes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVoiceNotes();
  }

  Future<void> _loadVoiceNotes() async {
    setState(() => _isLoading = true);
    try {
      final notes = await _apiService.getVoiceNotes();
      setState(() {
        _voiceNotes = notes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Voice Notes', style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _voiceNotes.isEmpty
              ? _buildEmptyState()
              : _buildVoiceNotesList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/voice-notes/create');
        },
        icon: const Icon(Icons.mic),
        label: const Text('Record'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mic_none, size: 80, color: context.colors.outline.withOpacity(0.5)),
          const VGap.lg(),
          Text(
            'No Voice Notes',
            style: context.text.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const VGap.xs(),
          Text(
            'Record your first voice note',
            style: context.text.bodyLarge?.copyWith(
              color: context.colors.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceNotesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _voiceNotes.length,
      itemBuilder: (context, index) {
        final note = _voiceNotes[index];
        return _buildVoiceNoteCard(note);
      },
    );
  }

  Widget _buildVoiceNoteCard(Map<String, dynamic> note) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: MemoryHubColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: Padded.all16,
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                context.colors.primary.withOpacity(0.2),
                context.colors.secondary.withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.mic,
            color: context.colors.primary,
            size: 24,
          ),
        ),
        title: Text(
          note['title'] ?? 'Untitled',
          style: context.text.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const VGap.xxs(),
            Text(
              _formatDuration(note['duration'] ?? 0),
              style: context.text.bodyMedium?.copyWith(
                color: context.colors.outline,
              ),
            ),
            if (note['transcription'] != null) ...[
              const VGap.xs(),
              Text(
                note['transcription'],
                style: context.text.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.play_arrow),
          onPressed: () {
            // Play voice note
          },
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
