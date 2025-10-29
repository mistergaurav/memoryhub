import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../services/family/family_service.dart';
import '../models/user_search_result.dart';

class UserSearchAutocomplete extends StatefulWidget {
  final Function(UserSearchResult) onUserSelected;
  
  const UserSearchAutocomplete({
    Key? key,
    required this.onUserSelected,
  }) : super(key: key);

  @override
  State<UserSearchAutocomplete> createState() => _UserSearchAutocompleteState();
}

class _UserSearchAutocompleteState extends State<UserSearchAutocomplete> {
  final FamilyService _familyService = FamilyService();
  final TextEditingController _controller = TextEditingController();
  List<UserSearchResult> _searchResults = [];
  bool _isLoading = false;
  String? _error;
  Timer? _debounce;

  static const Color _primaryTeal = Color(0xFF0E7C86);
  static const Color _accentAqua = Color(0xFF1FB7C9);
  static const Color _supportLight = Color(0xFFF2FBFC);
  static const Color _typographyDark = Color(0xFF0B1F32);
  static const Color _errorRed = Color(0xFFE63946);

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
        _error = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await _familyService.searchFamilyCircleUsers(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to search users';
          _isLoading = false;
          _searchResults = [];
        });
      }
    }
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchUsers(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: _supportLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _error != null ? _errorRed : _primaryTeal.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: TextField(
            controller: _controller,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              labelText: 'Search for user',
              hintText: 'Enter name or email',
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: _primaryTeal.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.search, size: 18, color: _primaryTeal),
              ),
              suffixIcon: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            style: GoogleFonts.inter(
              fontSize: 15,
              color: _typographyDark,
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: _errorRed,
            ),
          ),
        ],
        if (_searchResults.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _primaryTeal.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 250),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _searchResults.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: _primaryTeal.withOpacity(0.1),
              ),
              itemBuilder: (context, index) {
                final user = _searchResults[index];
                return ListTile(
                  onTap: () {
                    widget.onUserSelected(user);
                    _controller.text = user.fullName;
                    setState(() {
                      _searchResults = [];
                    });
                  },
                  leading: CircleAvatar(
                    backgroundColor: _accentAqua.withOpacity(0.2),
                    child: user.avatarUrl != null
                        ? ClipOval(
                            child: Image.network(
                              user.avatarUrl!,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stack) =>
                                  Icon(Icons.person, color: _accentAqua),
                            ),
                          )
                        : Icon(Icons.person, color: _accentAqua),
                  ),
                  title: Text(
                    user.fullName,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _typographyDark,
                    ),
                  ),
                  subtitle: user.email != null
                      ? Text(
                          user.email!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: _typographyDark.withOpacity(0.6),
                          ),
                        )
                      : null,
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: user.relationType == 'circle'
                              ? _primaryTeal.withOpacity(0.1)
                              : _accentAqua.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          user.relationType == 'circle' ? 'Circle' : 'Other',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: user.relationType == 'circle'
                                ? _primaryTeal
                                : _accentAqua,
                          ),
                        ),
                      ),
                      if (user.requiresApproval) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Approval Required',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFF59E0B),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ] else if (_controller.text.isNotEmpty && !_isLoading && _error == null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _supportLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.search_off, color: _typographyDark.withOpacity(0.3)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No users found. Try a different search term.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: _typographyDark.withOpacity(0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
