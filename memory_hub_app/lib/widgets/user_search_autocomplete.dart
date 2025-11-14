import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../services/family/family_service.dart';
import '../models/user_search_result.dart';
import 'package:memory_hub_app/design_system/design_tokens.dart';

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

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _controller.text = widget.initialValue!;
    }
    _animationController = AnimationController(
      vsync: this,
      duration: MemoryHubAnimations.normal,
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
        color: MemoryHubColors.teal600.withOpacity(0.1),
      ),
      itemBuilder: (context, index) => Padding(
        padding: EdgeInsets.symmetric(horizontal: MemoryHubSpacing.lg, vertical: MemoryHubSpacing.md),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: MemoryHubColors.gray200,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: MemoryHubSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 14,
                    decoration: BoxDecoration(
                      color: MemoryHubColors.gray200,
                      borderRadius: MemoryHubBorderRadius.xsRadius,
                    ),
                  ),
                  SizedBox(height: MemoryHubSpacing.sm),
                  Container(
                    width: 120,
                    height: 12,
                    decoration: BoxDecoration(
                      color: MemoryHubColors.gray200,
                      borderRadius: MemoryHubBorderRadius.xsRadius,
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
            borderRadius: MemoryHubBorderRadius.lgRadius,
            border: Border.all(
              color: _error != null 
                ? MemoryHubColors.red500 
                : _focusNode.hasFocus 
                  ? MemoryHubColors.cyan500 
                  : MemoryHubColors.teal600.withOpacity(0.2),
              width: _focusNode.hasFocus ? 2 : 1,
            ),
            boxShadow: _focusNode.hasFocus
                ? [
                    BoxShadow(
                      color: MemoryHubColors.cyan500.withOpacity(0.1),
                      blurRadius: MemoryHubSpacing.md,
                      offset: Offset(0, MemoryHubSpacing.xs),
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
                fontSize: MemoryHubTypography.bodyMedium,
                color: MemoryHubColors.gray900.withOpacity(0.4),
              ),
              prefixIcon: Padding(
                padding: EdgeInsets.all(MemoryHubSpacing.lg),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [MemoryHubColors.teal600, MemoryHubColors.cyan500],
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
                          Padding(
                            padding: EdgeInsets.only(right: MemoryHubSpacing.sm),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(MemoryHubColors.cyan500),
                              ),
                            ),
                          ),
                        IconButton(
                          icon: Icon(Icons.clear, color: MemoryHubColors.gray900.withOpacity(0.5)),
                          onPressed: _clearSearch,
                          tooltip: 'Clear search',
                          iconSize: 20,
                        ),
                      ],
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: MemoryHubSpacing.lg, vertical: MemoryHubSpacing.lg),
              labelStyle: GoogleFonts.inter(
                fontSize: MemoryHubTypography.bodyMedium,
                color: MemoryHubColors.teal600,
                fontWeight: MemoryHubTypography.medium,
              ),
            ),
            style: GoogleFonts.inter(
              fontSize: MemoryHubTypography.h5,
              color: MemoryHubColors.gray900,
              fontWeight: MemoryHubTypography.medium,
            ),
          ),
        ),

        // Helper Text
        if (widget.helpText != null && _controller.text.isEmpty) ...[
          SizedBox(height: MemoryHubSpacing.sm),
          Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: MemoryHubColors.teal600.withOpacity(0.6)),
              SizedBox(width: MemoryHubSpacing.xs),
              Expanded(
                child: Text(
                  widget.helpText!,
                  style: GoogleFonts.inter(
                    fontSize: MemoryHubTypography.bodySmall,
                    color: MemoryHubColors.gray900.withOpacity(0.6),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],

        // Minimum character hint
        if (_controller.text.isNotEmpty && _controller.text.length < 2) ...[
          SizedBox(height: MemoryHubSpacing.sm),
          Row(
            children: [
              Icon(Icons.keyboard, size: 14, color: MemoryHubColors.teal600.withOpacity(0.6)),
              SizedBox(width: MemoryHubSpacing.xs),
              Text(
                'Type at least 2 characters to search',
                style: GoogleFonts.inter(
                  fontSize: MemoryHubTypography.bodySmall,
                  color: MemoryHubColors.teal600.withOpacity(0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],

        // Error Message
        if (_error != null) ...[
          SizedBox(height: MemoryHubSpacing.sm),
          Container(
            padding: EdgeInsets.all(MemoryHubSpacing.md),
            decoration: BoxDecoration(
              color: MemoryHubColors.red500.withOpacity(0.08),
              borderRadius: MemoryHubBorderRadius.mdRadius,
              border: Border.all(color: MemoryHubColors.red500.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 18, color: MemoryHubColors.red500),
                SizedBox(width: MemoryHubSpacing.sm),
                Expanded(
                  child: Text(
                    _error!,
                    style: GoogleFonts.inter(
                      fontSize: MemoryHubTypography.bodyMedium,
                      color: MemoryHubColors.red500,
                      fontWeight: MemoryHubTypography.medium,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _searchUsers(_controller.text),
                  child: Text(
                    'Retry',
                    style: GoogleFonts.inter(
                      fontSize: MemoryHubTypography.bodySmall,
                      color: MemoryHubColors.red500,
                      fontWeight: MemoryHubTypography.semiBold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Search Results
        if (_showResults && _controller.text.length >= 2) ...[
          SizedBox(height: MemoryHubSpacing.md),
          FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: MemoryHubBorderRadius.lgRadius,
                border: Border.all(color: MemoryHubColors.teal600.withOpacity(0.15)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: MemoryHubSpacing.lg,
                    offset: Offset(0, MemoryHubSpacing.xs),
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
                              padding: EdgeInsets.all(MemoryHubSpacing.lg),
                              child: Row(
                                children: [
                                  Icon(Icons.people_alt_rounded, size: 18, color: MemoryHubColors.teal600),
                                  SizedBox(width: MemoryHubSpacing.sm),
                                  Text(
                                    '${_searchResults.length} ${_searchResults.length == 1 ? 'user' : 'users'} found',
                                    style: GoogleFonts.inter(
                                      fontSize: MemoryHubTypography.bodyMedium,
                                      fontWeight: MemoryHubTypography.semiBold,
                                      color: MemoryHubColors.gray900.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Divider(height: 1, color: MemoryHubColors.teal600.withOpacity(0.1)),
                            Expanded(
                              child: ListView.separated(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                itemCount: _searchResults.length,
                                separatorBuilder: (context, index) => Divider(
                                  height: 1,
                                  indent: 68,
                                  color: MemoryHubColors.teal600.withOpacity(0.1),
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
                                        padding: EdgeInsets.symmetric(horizontal: MemoryHubSpacing.lg, vertical: MemoryHubSpacing.md),
                                        child: Row(
                                          children: [
                                            // Avatar
                                            Container(
                                              width: 48,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [MemoryHubColors.teal600.withOpacity(0.2), MemoryHubColors.cyan500.withOpacity(0.2)],
                                                ),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: MemoryHubColors.teal600.withOpacity(0.3),
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
                                                            Icon(Icons.person_rounded, color: MemoryHubColors.cyan500, size: 24),
                                                      ),
                                                    )
                                                  : Icon(Icons.person_rounded, color: MemoryHubColors.cyan500, size: 24),
                                            ),
                                            SizedBox(width: MemoryHubSpacing.lg),
                                            // User Info
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    user.fullName,
                                                    style: GoogleFonts.inter(
                                                      fontSize: MemoryHubTypography.h5,
                                                      fontWeight: MemoryHubTypography.semiBold,
                                                      color: MemoryHubColors.gray900,
                                                      height: 1.2,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  if (user.email != null) ...[
                                                    SizedBox(height: MemoryHubSpacing.xs),
                                                    Row(
                                                      children: [
                                                        Icon(Icons.email_outlined, size: 12, color: MemoryHubColors.gray900.withOpacity(0.4)),
                                                        SizedBox(width: MemoryHubSpacing.xs),
                                                        Expanded(
                                                          child: Text(
                                                            user.email!,
                                                            style: GoogleFonts.inter(
                                                              fontSize: MemoryHubTypography.bodySmall,
                                                              color: MemoryHubColors.gray900.withOpacity(0.6),
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
                                            SizedBox(width: MemoryHubSpacing.sm),
                                            // Badges
                                            Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Container(
                                                  padding: EdgeInsets.symmetric(horizontal: MemoryHubSpacing.sm, vertical: MemoryHubSpacing.xs),
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: user.relationType == 'circle'
                                                          ? [MemoryHubColors.teal600.withOpacity(0.15), MemoryHubColors.teal600.withOpacity(0.08)]
                                                          : [MemoryHubColors.cyan500.withOpacity(0.15), MemoryHubColors.cyan500.withOpacity(0.08)],
                                                    ),
                                                    borderRadius: MemoryHubBorderRadius.mdRadius,
                                                    border: Border.all(
                                                      color: user.relationType == 'circle'
                                                          ? MemoryHubColors.teal600.withOpacity(0.3)
                                                          : MemoryHubColors.cyan500.withOpacity(0.3),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        user.relationType == 'circle' ? Icons.group : Icons.person_outline,
                                                        size: 12,
                                                        color: user.relationType == 'circle' ? MemoryHubColors.teal600 : MemoryHubColors.cyan500,
                                                      ),
                                                      SizedBox(width: MemoryHubSpacing.xs),
                                                      Text(
                                                        user.relationType == 'circle' ? 'Circle' : 'Other',
                                                        style: GoogleFonts.inter(
                                                          fontSize: MemoryHubTypography.bodySmall,
                                                          fontWeight: MemoryHubTypography.bold,
                                                          color: user.relationType == 'circle' ? MemoryHubColors.teal600 : MemoryHubColors.cyan500,
                                                          letterSpacing: 0.2,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                if (user.requiresApproval) ...[
                                                  SizedBox(height: MemoryHubSpacing.xs),
                                                  Container(
                                                    padding: EdgeInsets.symmetric(horizontal: MemoryHubSpacing.sm, vertical: MemoryHubSpacing.xs),
                                                    decoration: BoxDecoration(
                                                      color: MemoryHubColors.amber400.withOpacity(0.2),
                                                      borderRadius: MemoryHubBorderRadius.smRadius,
                                                      border: Border.all(
                                                        color: MemoryHubColors.amber500.withOpacity(0.3),
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(Icons.pending_actions, size: 10, color: MemoryHubColors.amber500),
                                                        SizedBox(width: MemoryHubSpacing.xs),
                                                        Text(
                                                          'Needs Approval',
                                                          style: GoogleFonts.inter(
                                                            fontSize: MemoryHubTypography.bodySmall,
                                                            fontWeight: MemoryHubTypography.bold,
                                                            color: MemoryHubColors.amber500,
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
                          padding: EdgeInsets.all(MemoryHubSpacing.xl),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [MemoryHubColors.gray50, MemoryHubColors.teal600.withOpacity(0.1)],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.person_search_outlined,
                                  size: 32,
                                  color: MemoryHubColors.teal600.withOpacity(0.5),
                                ),
                              ),
                              SizedBox(height: MemoryHubSpacing.lg),
                              Text(
                                'No users found',
                                style: GoogleFonts.inter(
                                  fontSize: MemoryHubTypography.h5,
                                  fontWeight: MemoryHubTypography.semiBold,
                                  color: MemoryHubColors.gray900,
                                ),
                              ),
                              SizedBox(height: MemoryHubSpacing.sm),
                              Text(
                                'Only users in your family circles can be found',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: MemoryHubTypography.bodyMedium,
                                  color: MemoryHubColors.gray900.withOpacity(0.6),
                                  height: 1.4,
                                ),
                              ),
                              SizedBox(height: MemoryHubSpacing.lg),
                              Container(
                                padding: EdgeInsets.all(MemoryHubSpacing.lg),
                                decoration: BoxDecoration(
                                  color: MemoryHubColors.teal600.withOpacity(0.05),
                                  borderRadius: MemoryHubBorderRadius.mdRadius,
                                  border: Border.all(
                                    color: MemoryHubColors.teal600.withOpacity(0.2),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.lightbulb_outline, size: 16, color: MemoryHubColors.teal600),
                                        SizedBox(width: MemoryHubSpacing.sm),
                                        Text(
                                          'How to add users:',
                                          style: GoogleFonts.inter(
                                            fontSize: MemoryHubTypography.bodySmall,
                                            fontWeight: MemoryHubTypography.semiBold,
                                            color: MemoryHubColors.teal600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: MemoryHubSpacing.sm),
                                    Text(
                                      '1. Create or join a family circle\n'
                                      '2. Invite users to your circle\n'
                                      '3. Once they join, they\'ll appear in search',
                                      style: GoogleFonts.inter(
                                        fontSize: MemoryHubTypography.bodySmall,
                                        color: MemoryHubColors.gray900.withOpacity(0.7),
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
