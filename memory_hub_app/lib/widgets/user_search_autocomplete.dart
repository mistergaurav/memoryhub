import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../services/family/family_service.dart';
import '../models/user_search_result.dart';

class UserSearchAutocomplete extends StatefulWidget {
  final Function(UserSearchResult) onUserSelected;
  final String? initialValue;
  final String? helpText;
  
  const UserSearchAutocomplete({
    Key? key,
    required this.onUserSelected,
    this.initialValue,
    this.helpText,
  }) : super(key: key);

  @override
  State<UserSearchAutocomplete> createState() => _UserSearchAutocompleteState();
}

class _UserSearchAutocompleteState extends State<UserSearchAutocomplete> with SingleTickerProviderStateMixin {
  final FamilyService _familyService = FamilyService();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<UserSearchResult> _searchResults = [];
  bool _isLoading = false;
  String? _error;
  Timer? _debounce;
  bool _showResults = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  static const Color _primaryTeal = Color(0xFF0E7C86);
  static const Color _accentAqua = Color(0xFF1FB7C9);
  static const Color _supportLight = Color(0xFFF2FBFC);
  static const Color _typographyDark = Color(0xFF0B1F32);
  static const Color _errorRed = Color(0xFFE63946);
  static const Color _successGreen = Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _controller.text = widget.initialValue!;
    }
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        // Hide results when focus is lost
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            setState(() => _showResults = false);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
        _error = null;
        _showResults = false;
      });
      return;
    }

    // Minimum 2 characters for search
    if (query.trim().length < 2) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
        _error = null;
        _showResults = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _showResults = true;
    });

    _animationController.forward();

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
          _error = 'Unable to search users. Please try again.';
          _isLoading = false;
          _searchResults = [];
        });
      }
    }
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchUsers(value);
    });
  }

  void _clearSearch() {
    _controller.clear();
    setState(() {
      _searchResults = [];
      _isLoading = false;
      _error = null;
      _showResults = false;
    });
    _animationController.reverse();
    _focusNode.unfocus();
  }

  Widget _buildLoadingSkeleton() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: _primaryTeal.withOpacity(0.1),
      ),
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 120,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search Input
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _error != null 
                ? _errorRed 
                : _focusNode.hasFocus 
                  ? _accentAqua 
                  : _primaryTeal.withOpacity(0.2),
              width: _focusNode.hasFocus ? 2 : 1,
            ),
            boxShadow: _focusNode.hasFocus
                ? [
                    BoxShadow(
                      color: _accentAqua.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              labelText: 'Search for user',
              hintText: 'Type name, email, or username...',
              hintStyle: GoogleFonts.inter(
                fontSize: 14,
                color: _typographyDark.withOpacity(0.4),
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.all(14),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primaryTeal, _accentAqua],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.search, size: 14, color: Colors.white),
                ),
              ),
              suffixIcon: _controller.text.isNotEmpty
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isLoading)
                          const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(_accentAqua),
                              ),
                            ),
                          ),
                        IconButton(
                          icon: Icon(Icons.clear, color: _typographyDark.withOpacity(0.5)),
                          onPressed: _clearSearch,
                          tooltip: 'Clear search',
                          iconSize: 20,
                        ),
                      ],
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              labelStyle: GoogleFonts.inter(
                fontSize: 14,
                color: _primaryTeal,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: GoogleFonts.inter(
              fontSize: 15,
              color: _typographyDark,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // Helper Text
        if (widget.helpText != null && _controller.text.isEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: _primaryTeal.withOpacity(0.6)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.helpText!,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: _typographyDark.withOpacity(0.6),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],

        // Minimum character hint
        if (_controller.text.isNotEmpty && _controller.text.length < 2) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.keyboard, size: 14, color: _primaryTeal.withOpacity(0.6)),
              const SizedBox(width: 6),
              Text(
                'Type at least 2 characters to search',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: _primaryTeal.withOpacity(0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],

        // Error Message
        if (_error != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _errorRed.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _errorRed.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 18, color: _errorRed),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _error!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: _errorRed,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _searchUsers(_controller.text),
                  child: Text(
                    'Retry',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: _errorRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Search Results
        if (_showResults && _controller.text.length >= 2) ...[
          const SizedBox(height: 12),
          FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _primaryTeal.withOpacity(0.15)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              constraints: const BoxConstraints(maxHeight: 320),
              child: _isLoading
                  ? _buildLoadingSkeleton()
                  : _searchResults.isNotEmpty
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(Icons.people_alt_rounded, size: 18, color: _primaryTeal),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_searchResults.length} ${_searchResults.length == 1 ? 'user' : 'users'} found',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _typographyDark.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Divider(height: 1, color: _primaryTeal.withOpacity(0.1)),
                            Expanded(
                              child: ListView.separated(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                itemCount: _searchResults.length,
                                separatorBuilder: (context, index) => Divider(
                                  height: 1,
                                  indent: 68,
                                  color: _primaryTeal.withOpacity(0.1),
                                ),
                                itemBuilder: (context, index) {
                                  final user = _searchResults[index];
                                  return Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        widget.onUserSelected(user);
                                        _controller.text = user.fullName;
                                        setState(() {
                                          _searchResults = [];
                                          _showResults = false;
                                        });
                                        _focusNode.unfocus();
                                        _animationController.reverse();
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        child: Row(
                                          children: [
                                            // Avatar
                                            Container(
                                              width: 48,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [_primaryTeal.withOpacity(0.2), _accentAqua.withOpacity(0.2)],
                                                ),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: _primaryTeal.withOpacity(0.3),
                                                  width: 2,
                                                ),
                                              ),
                                              child: user.avatarUrl != null
                                                  ? ClipOval(
                                                      child: Image.network(
                                                        user.avatarUrl!,
                                                        width: 48,
                                                        height: 48,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (context, error, stack) =>
                                                            Icon(Icons.person_rounded, color: _accentAqua, size: 24),
                                                      ),
                                                    )
                                                  : Icon(Icons.person_rounded, color: _accentAqua, size: 24),
                                            ),
                                            const SizedBox(width: 14),
                                            // User Info
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    user.fullName,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.w600,
                                                      color: _typographyDark,
                                                      height: 1.2,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  if (user.email != null) ...[
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        Icon(Icons.email_outlined, size: 12, color: _typographyDark.withOpacity(0.4)),
                                                        const SizedBox(width: 4),
                                                        Expanded(
                                                          child: Text(
                                                            user.email!,
                                                            style: GoogleFonts.inter(
                                                              fontSize: 12,
                                                              color: _typographyDark.withOpacity(0.6),
                                                              height: 1.3,
                                                            ),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            // Badges
                                            Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: user.relationType == 'circle'
                                                          ? [_primaryTeal.withOpacity(0.15), _primaryTeal.withOpacity(0.08)]
                                                          : [_accentAqua.withOpacity(0.15), _accentAqua.withOpacity(0.08)],
                                                    ),
                                                    borderRadius: BorderRadius.circular(10),
                                                    border: Border.all(
                                                      color: user.relationType == 'circle'
                                                          ? _primaryTeal.withOpacity(0.3)
                                                          : _accentAqua.withOpacity(0.3),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        user.relationType == 'circle' ? Icons.group : Icons.person_outline,
                                                        size: 12,
                                                        color: user.relationType == 'circle' ? _primaryTeal : _accentAqua,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        user.relationType == 'circle' ? 'Circle' : 'Other',
                                                        style: GoogleFonts.inter(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w700,
                                                          color: user.relationType == 'circle' ? _primaryTeal : _accentAqua,
                                                          letterSpacing: 0.2,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                if (user.requiresApproval) ...[
                                                  const SizedBox(height: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFFEF3C7),
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(
                                                        color: const Color(0xFFF59E0B).withOpacity(0.3),
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        const Icon(Icons.pending_actions, size: 10, color: Color(0xFFF59E0B)),
                                                        const SizedBox(width: 3),
                                                        Text(
                                                          'Needs Approval',
                                                          style: GoogleFonts.inter(
                                                            fontSize: 9,
                                                            fontWeight: FontWeight.w700,
                                                            color: const Color(0xFFF59E0B),
                                                            letterSpacing: 0.1,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        )
                      : Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [_supportLight, _primaryTeal.withOpacity(0.1)],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.person_search_outlined,
                                  size: 32,
                                  color: _primaryTeal.withOpacity(0.5),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No users found',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _typographyDark,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Only users in your family circles can be found',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: _typographyDark.withOpacity(0.6),
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: _primaryTeal.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _primaryTeal.withOpacity(0.2),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.lightbulb_outline, size: 16, color: _primaryTeal),
                                        const SizedBox(width: 8),
                                        Text(
                                          'How to add users:',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: _primaryTeal,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '1. Create or join a family circle\n'
                                      '2. Invite users to your circle\n'
                                      '3. Once they join, they\'ll appear in search',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: _typographyDark.withOpacity(0.7),
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
            ),
          ),
        ],
      ],
    );
  }
}
