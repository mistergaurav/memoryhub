import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';

class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({super.key});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _templates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);
    try {
      final templates = await _apiService.getMemoryTemplates();
      setState(() {
        _templates = templates;
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
        title: Text('Memory Templates', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.pushNamed(context, '/templates/create');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _templates.isEmpty
              ? _buildEmptyState()
              : _buildTemplatesList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined, size: 80, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'No Templates',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create reusable memory templates',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplatesList() {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _templates.length,
      itemBuilder: (context, index) {
        final template = _templates[index];
        return _buildTemplateCard(template);
      },
    );
  }

  Widget _buildTemplateCard(Map<String, dynamic> template) {
    final colors = [
      [Colors.purple, Colors.deepPurple],
      [Colors.blue, Colors.indigo],
      [Colors.green, Colors.teal],
      [Colors.orange, Colors.deepOrange],
      [Colors.pink, Colors.red],
    ];
    final colorPair = colors[template['name'].hashCode % colors.length];

    return InkWell(
      onTap: () {
        _showTemplatePreview(template);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colorPair,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colorPair[0].withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.description,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const Spacer(),
              Text(
                template['name'] ?? 'Untitled',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              if (template['description'] != null)
                Text(
                  template['description'],
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.auto_awesome, size: 14, color: Colors.white.withOpacity(0.8)),
                  const SizedBox(width: 4),
                  Text(
                    '${template['fields']?.length ?? 0} fields',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTemplatePreview(Map<String, dynamic> template) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template['name'] ?? 'Untitled',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (template['description'] != null)
                          Text(
                            template['description'],
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: template['fields']?.length ?? 0,
                itemBuilder: (context, index) {
                  final field = template['fields'][index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Icon(
                        _getFieldIcon(field['type']),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(
                        field['name'] ?? 'Field ${index + 1}',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        field['type'] ?? 'text',
                        style: GoogleFonts.inter(fontSize: 13),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/memories/create', arguments: template);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Use Template'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFieldIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'text':
        return Icons.text_fields;
      case 'number':
        return Icons.numbers;
      case 'date':
        return Icons.calendar_today;
      case 'image':
        return Icons.image;
      default:
        return Icons.input;
    }
  }
}
