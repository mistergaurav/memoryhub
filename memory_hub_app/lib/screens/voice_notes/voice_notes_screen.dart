import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';

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
        title: Text('Voice Notes', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
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
          Icon(Icons.mic_none, size: 80, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'No Voice Notes',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Record your first voice note',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.grey,
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.2),
                Theme.of(context).colorScheme.secondary.withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.mic,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
        ),
        title: Text(
          note['title'] ?? 'Untitled',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              _formatDuration(note['duration'] ?? 0),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            if (note['transcription'] != null) ...[
              const SizedBox(height: 8),
              Text(
                note['transcription'],
                style: GoogleFonts.inter(fontSize: 13),
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
