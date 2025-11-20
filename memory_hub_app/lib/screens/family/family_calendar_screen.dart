import 'package:flutter/material.dart';
import '../../services/family/family_service.dart';
import '../../models/family/family_calendar.dart';
import '../../models/family/paginated_response.dart';
import '../../widgets/enhanced_empty_state.dart';
import '../../widgets/shimmer_loading.dart';
import '../../dialogs/family/add_event_dialog.dart';
import '../../design_system/design_system.dart';
import 'event_detail_screen.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../design_system/layout/padded.dart';

enum CalendarView { month, agenda }

class FamilyCalendarScreen extends StatefulWidget {
  const FamilyCalendarScreen({Key? key}) : super(key: key);

  @override
  State<FamilyCalendarScreen> createState() => _FamilyCalendarScreenState();
}

class _FamilyCalendarScreenState extends State<FamilyCalendarScreen> with SingleTickerProviderStateMixin {
  final FamilyService _familyService = FamilyService();
  List<FamilyCalendarEvent> _events = [];
  List<FamilyCalendarEvent> _upcomingBirthdays = [];
  bool _isLoading = true;
  String? _error;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  CalendarView _calendarView = CalendarView.month;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!mounted) return;
      if (_tabController.index == 0) {
        setState(() => _calendarView = CalendarView.month);
      } else {
        setState(() => _calendarView = CalendarView.agenda);
      }
    });
    _loadEvents();
    _loadUpcomingBirthdays();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final startDate = DateTime(_focusedDay.year, _focusedDay.month, 1);
      final endDate = DateTime(_focusedDay.year, _focusedDay.month + 1, 0, 23, 59, 59);
      final response = await _familyService.getCalendarEvents(
        startDate: startDate,
        endDate: endDate,
        pageSize: 100,
      );
      if (!mounted) return;
      setState(() {
        _events = response.items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUpcomingBirthdays() async {
    if (!mounted) return;
    try {
      final birthdays = await _familyService.getUpcomingBirthdays(daysAhead: 30);
      if (!mounted) return;
      setState(() {
        _upcomingBirthdays = birthdays;
      });
    } catch (e) {
    }
  }

  Future<void> _refreshEvents() async {
    await Future.wait([
      _loadEvents(),
      _loadUpcomingBirthdays(),
    ]);
  }

  List<FamilyCalendarEvent> _getEventsForDay(DateTime day) {
    final localDay = DateTime(day.year, day.month, day.day);
    return _events.where((event) {
      final eventDate = DateTime(event.startDate.year, event.startDate.month, event.startDate.day);
      if (isSameDay(eventDate, localDay)) return true;
      
      if (event.endDate != null) {
        final endDate = DateTime(event.endDate!.year, event.endDate!.month, event.endDate!.day);
        return !localDay.isBefore(eventDate) && !localDay.isAfter(endDate);
      }
      return false;
    }).toList();
  }

  List<FamilyCalendarEvent> _getAllUpcomingEvents() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _events
        .where((event) {
          final eventDate = DateTime(event.startDate.year, event.startDate.month, event.startDate.day);
          return eventDate.isAfter(today) || isSameDay(eventDate, today);
        })
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  void _showAddEventDialog() {
    showDialog(
      context: context,
      builder: (context) => AddEventDialog(
        onSubmit: _handleAddEvent,
      ),
    );
  }

  Future<void> _handleAddEvent(Map<String, dynamic> data) async {
    final tempEvent = FamilyCalendarEvent(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      title: data['title'],
      description: data['description'],
      startDate: DateTime.parse(data['event_date']),
      endDate: data['end_date'] != null ? DateTime.parse(data['end_date']) : null,
      isAllDay: data['is_all_day'] ?? false,
      location: data['location'],
      eventType: data['event_type'],
      recurrenceRule: data['recurrence'],
      familyCircleIds: const [],
      attendeeIds: const [],
      createdBy: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (mounted) {
      setState(() {
        _events.add(tempEvent);
      });
    }

    try {
      final result = await _familyService.createCalendarEvent(data);
      
      if (!mounted) return;
      
      setState(() {
        _events.removeWhere((e) => e.id == tempEvent.id);
        if (result['event'] != null) {
          _events.add(FamilyCalendarEvent.fromJson(result['event']));
        }
      });

      final conflicts = result['conflicts'] ?? 0;
      final warning = result['conflict_warning'];
      
      if (mounted) {
        if (conflicts > 0 && warning != null) {
          AppSnackbar.info(context, warning);
        } else {
          AppSnackbar.success(context, 'Event added successfully');
        }
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _events.removeWhere((e) => e.id == tempEvent.id);
      });
      
      if (mounted) {
        AppSnackbar.error(context, 'Failed to add event: ${e.toString().replaceAll('Exception: ', '')}');
      }
    }
  }

  void _navigateToEventDetail(FamilyCalendarEvent event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailScreen(
          eventId: event.id,
          initialEvent: event,
        ),
      ),
    ).then((deleted) {
      if (deleted == true) {
        _refreshEvents();
      }
    });
  }

  int _getDaysToBirthday(DateTime birthday) {
    final now = DateTime.now();
    final thisYear = DateTime(now.year, birthday.month, birthday.day);
    final nextYear = DateTime(now.year + 1, birthday.month, birthday.day);
    
    if (thisYear.isAfter(now) || isSameDay(thisYear, now)) {
      return thisYear.difference(now).inDays;
    } else {
      return nextYear.difference(now).inDays;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          if (_upcomingBirthdays.isNotEmpty) _buildUpcomingBirthdaysSection(),
          _buildViewToggle(),
          if (_calendarView == CalendarView.month) ...[
            _buildCalendarWidget(),
            _buildSelectedDayHeader(),
            _buildSelectedDayEvents(),
          ] else ...[
            _buildAgendaView(),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'family_calendar_fab',
        onPressed: _showAddEventDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Event'),
        backgroundColor: DesignTokens.primaryColor,
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Family Calendar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                MemoryHubColors.cyan500,
                MemoryHubColors.cyan400,
                MemoryHubColors.cyan300,
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                bottom: -30,
                child: Icon(
                  Icons.calendar_month,
                  size: 140,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.today),
          onPressed: () {
            setState(() {
              _focusedDay = DateTime.now();
              _selectedDay = DateTime.now();
            });
            _loadEvents();
          },
          tooltip: 'Go to today',
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _refreshEvents,
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  Widget _buildUpcomingBirthdaysSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: Spacing.edgeInsetsFromLTRB(Spacing.lg, Spacing.lg, Spacing.lg, Spacing.sm),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [MemoryHubColors.pink500, MemoryHubColors.pink400],
          ),
          borderRadius: MemoryHubBorderRadius.lgRadius,
          boxShadow: [
            BoxShadow(
              color: MemoryHubColors.pink500.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: MemoryHubBorderRadius.lgRadius,
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => _buildBirthdaysDialog(),
              );
            },
            child: Padded.all(
              Spacing.lg,
              child: Row(
                children: [
                  const Icon(Icons.cake, color: Colors.white, size: 28),
                  HGap.md(),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Upcoming Birthdays',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: MemoryHubTypography.h4,
                            fontWeight: MemoryHubTypography.bold,
                          ),
                        ),
                        VGap.xs(),
                        Text(
                          '${_upcomingBirthdays.length} ${_upcomingBirthdays.length == 1 ? 'birthday' : 'birthdays'} in the next 30 days',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: MemoryHubTypography.bodySmall,
                          ),
                        ),
                        if (_upcomingBirthdays.isNotEmpty) ...[
                          VGap.sm(),
                          _buildNextBirthdayPreview(),
                        ],
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white, size: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNextBirthdayPreview() {
    final nextBirthday = _upcomingBirthdays.first;
    final daysUntil = _getDaysToBirthday(nextBirthday.startDate);
    
    return Container(
      padding: Spacing.edgeInsetsSymmetric(horizontal: Spacing.sm, vertical: Spacing.xs),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: MemoryHubBorderRadius.smRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.celebration, color: Colors.white, size: 16),
          HGap.xs(),
          Flexible(
            child: Text(
              daysUntil == 0
                  ? '${nextBirthday.title} is TODAY! 🎉'
                  : '${nextBirthday.title} in $daysUntil ${daysUntil == 1 ? 'day' : 'days'}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: MemoryHubTypography.bodySmall,
                fontWeight: MemoryHubTypography.semiBold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBirthdaysDialog() {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.cake, color: MemoryHubColors.pink500),
          HGap.sm(),
          Text('Upcoming Birthdays'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: _upcomingBirthdays.length,
          itemBuilder: (context, index) {
            final birthday = _upcomingBirthdays[index];
            final daysUntil = _getDaysToBirthday(birthday.startDate);
            
            return Card(
              margin: Spacing.edgeInsetsOnly(bottom: Spacing.sm),
              child: ListTile(
                leading: Container(
                  padding: Spacing.edgeInsetsAll(Spacing.sm),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [MemoryHubColors.pink500, MemoryHubColors.pink400],
                    ),
                    borderRadius: MemoryHubBorderRadius.smRadius,
                  ),
                  child: const Icon(Icons.cake, color: Colors.white, size: 20),
                ),
                title: Text(
                  birthday.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  daysUntil == 0
                      ? 'Today! 🎉'
                      : 'In $daysUntil ${daysUntil == 1 ? 'day' : 'days'} • ${DateFormat('MMM d').format(birthday.startDate)}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToEventDetail(birthday);
                },
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildViewToggle() {
    return SliverToBoxAdapter(
      child: Container(
        margin: Spacing.edgeInsetsSymmetric(horizontal: Spacing.lg, vertical: Spacing.sm),
        decoration: BoxDecoration(
          color: MemoryHubColors.gray200,
          borderRadius: MemoryHubBorderRadius.mdRadius,
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            gradient: const LinearGradient(
              colors: [MemoryHubColors.cyan500, MemoryHubColors.cyan400],
            ),
            borderRadius: MemoryHubBorderRadius.mdRadius,
          ),
          labelColor: Colors.white,
          unselectedLabelColor: MemoryHubColors.gray700,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(
              icon: Icon(Icons.calendar_month),
              text: 'Month',
            ),
            Tab(
              icon: Icon(Icons.list),
              text: 'Agenda',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarWidget() {
    return SliverToBoxAdapter(
      child: Card(
        margin: EdgeInsets.all(MemoryHubSpacing.lg),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: MemoryHubBorderRadius.xlRadius,
        ),
        child: TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          eventLoader: _getEventsForDay,
          onDaySelected: (selectedDay, focusedDay) {
            if (!mounted) return;
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onFormatChanged: (format) {
            if (!mounted) return;
            setState(() {
              _calendarFormat = format;
            });
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
            _loadEvents();
          },
          calendarStyle: CalendarStyle(
            selectedDecoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [MemoryHubColors.cyan500, MemoryHubColors.cyan400],
              ),
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: MemoryHubColors.cyan500.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            markerDecoration: const BoxDecoration(
              color: MemoryHubColors.pink500,
              shape: BoxShape.circle,
            ),
            markersMaxCount: 3,
            markerSize: 6,
            outsideDaysVisible: false,
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: true,
            titleCentered: true,
            formatButtonDecoration: BoxDecoration(
              border: Border.all(color: DesignTokens.primaryColor),
              borderRadius: MemoryHubBorderRadius.smRadius,
            ),
            formatButtonTextStyle: const TextStyle(
              color: DesignTokens.primaryColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedDayHeader() {
    final dayEvents = _getEventsForDay(_selectedDay);
    
    return SliverPadding(
      padding: Spacing.edgeInsetsFromLTRB(Spacing.lg, Spacing.sm, Spacing.lg, Spacing.sm),
      sliver: SliverToBoxAdapter(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                DateFormat('EEEE, MMMM d, yyyy').format(_selectedDay),
                style: const TextStyle(
                  fontSize: MemoryHubTypography.h3,
                  fontWeight: MemoryHubTypography.bold,
                ),
              ),
            ),
            if (dayEvents.isNotEmpty)
              Container(
                padding: Spacing.edgeInsetsSymmetric(horizontal: MemoryHubSpacing.md, vertical: Spacing.xs),
                decoration: BoxDecoration(
                  color: DesignTokens.primaryColor.withValues(alpha: 0.1),
                  borderRadius: MemoryHubBorderRadius.mdRadius,
                ),
                child: Text(
                  '${dayEvents.length} ${dayEvents.length == 1 ? 'event' : 'events'}',
                  style: const TextStyle(
                    color: DesignTokens.primaryColor,
                    fontWeight: MemoryHubTypography.bold,
                    fontSize: MemoryHubTypography.bodySmall,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedDayEvents() {
    if (_isLoading) {
      return SliverPadding(
        padding: Spacing.edgeInsetsAll(Spacing.lg),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => const ShimmerEventCard(),
            childCount: 3,
          ),
        ),
      );
    }

    if (_error != null) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: MemoryHubColors.red300),
              VGap.lg(),
              Text(
                _error!.replaceAll('Exception: ', ''),
                style: TextStyle(color: MemoryHubColors.gray600),
                textAlign: TextAlign.center,
              ),
              VGap.xl(),
              PrimaryButton(
                onPressed: _loadEvents,
                label: 'Retry',
                leading: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
      );
    }

    final dayEvents = _getEventsForDay(_selectedDay);

    if (dayEvents.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.event_busy,
                size: 64,
                color: MemoryHubColors.gray300,
              ),
              VGap.lg(),
              Text(
                'No events for this day',
                style: TextStyle(
                  fontSize: MemoryHubTypography.h5,
                  color: MemoryHubColors.gray600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: Spacing.edgeInsetsFromLTRB(Spacing.lg, 0, Spacing.lg, 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final event = dayEvents[index];
            return _buildEventCard(event, index);
          },
          childCount: dayEvents.length,
        ),
      ),
    );
  }

  Widget _buildAgendaView() {
    if (_isLoading) {
      return SliverPadding(
        padding: Spacing.edgeInsetsAll(Spacing.lg),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => const ShimmerEventCard(),
            childCount: 5,
          ),
        ),
      );
    }

    if (_error != null) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: MemoryHubColors.red300),
              VGap.lg(),
              Text(
                _error!.replaceAll('Exception: ', ''),
                style: TextStyle(color: MemoryHubColors.gray600),
                textAlign: TextAlign.center,
              ),
              VGap.xl(),
              PrimaryButton(
                onPressed: _loadEvents,
                label: 'Retry',
                leading: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
      );
    }

    final upcomingEvents = _getAllUpcomingEvents();

    if (upcomingEvents.isEmpty) {
      return SliverFillRemaining(
        child: EnhancedEmptyState(
          icon: Icons.event_available,
          title: 'No Upcoming Events',
          message: 'Add events to see them here',
        ),
      );
    }

    final groupedEvents = <String, List<FamilyCalendarEvent>>{};
    for (var event in upcomingEvents) {
      final dateKey = DateFormat('yyyy-MM-dd').format(event.startDate);
      groupedEvents.putIfAbsent(dateKey, () => []).add(event);
    }

    final sortedDates = groupedEvents.keys.toList()
      ..sort((a, b) => DateTime.parse(a).compareTo(DateTime.parse(b)));

    return SliverPadding(
      padding: Spacing.edgeInsetsFromLTRB(Spacing.lg, 0, Spacing.lg, 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final dateKey = sortedDates[index];
            final events = groupedEvents[dateKey]!;
            final date = DateTime.parse(dateKey);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: Spacing.edgeInsetsSymmetric(vertical: MemoryHubSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        padding: Spacing.edgeInsetsAll(Spacing.md),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [MemoryHubColors.cyan500, MemoryHubColors.cyan400],
                          ),
                          borderRadius: MemoryHubBorderRadius.mdRadius,
                        ),
                        child: Column(
                          children: [
                            Text(
                              DateFormat('d').format(date),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: MemoryHubTypography.h3,
                                fontWeight: MemoryHubTypography.bold,
                              ),
                            ),
                            Text(
                              DateFormat('MMM').format(date).toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: MemoryHubTypography.semiBold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      HGap.md(),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('EEEE').format(date),
                              style: const TextStyle(
                                fontSize: MemoryHubTypography.h4,
                                fontWeight: MemoryHubTypography.bold,
                              ),
                            ),
                            Text(
                              DateFormat('MMMM d, yyyy').format(date),
                              style: TextStyle(
                                fontSize: MemoryHubTypography.bodySmall,
                                color: MemoryHubColors.gray600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: Spacing.edgeInsetsSymmetric(horizontal: Spacing.sm, vertical: Spacing.xs),
                        decoration: BoxDecoration(
                          color: DesignTokens.primaryColor.withValues(alpha: 0.1),
                          borderRadius: MemoryHubBorderRadius.smRadius,
                        ),
                        child: Text(
                          '${events.length}',
                          style: const TextStyle(
                            color: DesignTokens.primaryColor,
                            fontWeight: MemoryHubTypography.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ...events.asMap().entries.map((entry) {
                  return _buildEventCard(entry.value, entry.key);
                }).toList(),
                VGap.sm(),
              ],
            );
          },
          childCount: sortedDates.length,
        ),
      ),
    );
  }

  Widget _buildEventCard(FamilyCalendarEvent event, int index) {
    final gradient = _getEventGradient(event.eventType);
    final icon = _getEventIcon(event.eventType);
    final isBirthday = event.eventType == 'birthday';
    
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: MemoryHubAnimations.normal.inMilliseconds + (index * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Card(
        margin: Spacing.edgeInsetsOnly(bottom: Spacing.md),
        elevation: isBirthday ? 6 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: MemoryHubBorderRadius.lgRadius,
          side: isBirthday
              ? const BorderSide(color: MemoryHubColors.pink500, width: 2)
              : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: MemoryHubBorderRadius.lgRadius,
          onTap: () => _navigateToEventDetail(event),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: MemoryHubBorderRadius.lgRadius,
              gradient: isBirthday
                  ? LinearGradient(
                      colors: [
                        gradient[0].withValues(alpha: 0.05),
                        gradient[1].withValues(alpha: 0.05),
                      ],
                    )
                  : null,
            ),
            child: Padded.all(
              Spacing.lg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: Spacing.edgeInsetsAll(Spacing.sm),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: gradient),
                          borderRadius: MemoryHubBorderRadius.mdRadius,
                          boxShadow: [
                            BoxShadow(
                              color: gradient[0].withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(icon, color: Colors.white, size: 20),
                      ),
                      HGap.md(),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    event.title,
                                    style: const TextStyle(
                                      fontSize: MemoryHubTypography.h5,
                                      fontWeight: MemoryHubTypography.bold,
                                    ),
                                  ),
                                ),
                                if (event.recurrenceRule != null && event.recurrenceRule != 'none')
                                  Tooltip(
                                    message: _formatRecurrence(event.recurrenceRule!),
                                    child: Container(
                                      padding: Spacing.edgeInsetsSymmetric(horizontal: Spacing.sm, vertical: Spacing.xs),
                                      decoration: BoxDecoration(
                                        color: MemoryHubColors.blue50,
                                        borderRadius: MemoryHubBorderRadius.smRadius,
                                        border: Border.all(color: MemoryHubColors.blue200),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.repeat, size: 12, color: MemoryHubColors.blue700),
                                          HGap.xs(),
                                          Text(
                                            _getRecurrenceShortForm(event.recurrenceRule!),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: MemoryHubTypography.bold,
                                              color: MemoryHubColors.blue700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            VGap.xs(),
                            Row(
                              children: [
                                Icon(
                                  event.isAllDay ? Icons.calendar_today : Icons.access_time,
                                  size: 14,
                                  color: MemoryHubColors.gray600,
                                ),
                                HGap.xs(),
                                Text(
                                  event.isAllDay
                                      ? 'All Day'
                                      : DateFormat('h:mm a').format(event.startDate.toLocal()),
                                  style: TextStyle(
                                    fontSize: MemoryHubTypography.bodySmall,
                                    color: MemoryHubColors.gray600,
                                  ),
                                ),
                                if (event.endDate != null && !event.isAllDay) ...[
                                  Text(
                                    ' - ${DateFormat('h:mm a').format(event.endDate!.toLocal())}',
                                    style: TextStyle(
                                      fontSize: MemoryHubTypography.bodySmall,
                                      color: MemoryHubColors.gray600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (event.description != null && event.description!.isNotEmpty) ...[
                    VGap.md(),
                    Text(
                      event.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: MemoryHubTypography.bodySmall,
                        color: MemoryHubColors.gray700,
                        height: 1.4,
                      ),
                    ),
                  ],
                  if (event.location != null && event.location!.isNotEmpty) ...[
                    VGap.sm(),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: MemoryHubColors.gray600),
                        HGap.xs(),
                        Expanded(
                          child: Text(
                            event.location!,
                            style: TextStyle(
                              fontSize: MemoryHubTypography.bodySmall,
                              color: MemoryHubColors.gray600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  VGap.md(),
                  Row(
                    children: [
                      Container(
                        padding: Spacing.edgeInsetsSymmetric(horizontal: Spacing.sm, vertical: Spacing.xs),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: gradient),
                          borderRadius: MemoryHubBorderRadius.smRadius,
                        ),
                        child: Text(
                          _formatEventType(event.eventType),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: MemoryHubTypography.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (event.attendeeIds.isNotEmpty)
                        Row(
                          children: [
                            Icon(Icons.people, size: 14, color: MemoryHubColors.gray600),
                            HGap.xs(),
                            Text(
                              '${event.attendeeIds.length}',
                              style: TextStyle(
                                fontSize: MemoryHubTypography.bodySmall,
                                color: MemoryHubColors.gray600,
                              ),
                            ),
                          ],
                        ),
                      if (event.autoGenerated) ...[
                        HGap.sm(),
                        Tooltip(
                          message: 'Auto-generated from Family Tree',
                          child: Icon(
                            Icons.auto_awesome,
                            size: 16,
                            color: MemoryHubColors.blue400,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Color> _getEventGradient(String eventType) {
    switch (eventType) {
      case 'birthday':
        return [MemoryHubColors.pink500, MemoryHubColors.pink400];
      case 'death_anniversary':
        return [MemoryHubColors.gray600, MemoryHubColors.gray400];
      case 'anniversary':
        return [MemoryHubColors.pink600, MemoryHubColors.pink500];
      case 'gathering':
        return [MemoryHubColors.purple600, MemoryHubColors.purple500];
      case 'holiday':
        return [MemoryHubColors.amber500, MemoryHubColors.amber400];
      case 'historical_event':
        return [MemoryHubColors.amber800, MemoryHubColors.amber700];
      case 'reminder':
        return [MemoryHubColors.green500, MemoryHubColors.green400];
      default:
        return [MemoryHubColors.cyan500, MemoryHubColors.cyan400];
    }
  }

  IconData _getEventIcon(String eventType) {
    switch (eventType) {
      case 'birthday':
        return Icons.cake;
      case 'anniversary':
      case 'death_anniversary':
        return Icons.favorite;
      case 'gathering':
        return Icons.groups;
      case 'holiday':
        return Icons.celebration;
      case 'reminder':
        return Icons.notifications;
      case 'historical_event':
        return Icons.history_edu;
      default:
        return Icons.event;
    }
  }

  String _formatEventType(String eventType) {
    switch (eventType) {
      case 'birthday':
        return 'Birthday';
      case 'anniversary':
        return 'Anniversary';
      case 'death_anniversary':
        return 'Memorial';
      case 'gathering':
        return 'Gathering';
      case 'holiday':
        return 'Holiday';
      case 'reminder':
        return 'Reminder';
      case 'historical_event':
        return 'Historical';
      default:
        return 'Event';
    }
  }

  String _formatRecurrence(String recurrence) {
    switch (recurrence) {
      case 'daily':
        return 'Repeats daily';
      case 'weekly':
        return 'Repeats weekly';
      case 'monthly':
        return 'Repeats monthly';
      case 'yearly':
        return 'Repeats yearly';
      default:
        return 'Does not repeat';
    }
  }

  String _getRecurrenceShortForm(String recurrence) {
    switch (recurrence) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      case 'yearly':
        return 'Yearly';
      default:
        return '';
    }
  }
}
