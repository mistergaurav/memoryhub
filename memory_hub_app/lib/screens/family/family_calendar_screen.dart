import 'package:flutter/material.dart';
import '../../services/family/family_service.dart';
import '../../models/family/family_calendar.dart';
import '../../models/family/paginated_response.dart';
import '../../widgets/enhanced_empty_state.dart';
import '../../widgets/shimmer_loading.dart';
import '../../dialogs/family/add_event_dialog.dart';
import '../../design_system/design_tokens.dart';
import 'event_detail_screen.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              conflicts > 0 && warning != null
                  ? warning
                  : 'Event added successfully',
            ),
            backgroundColor: conflicts > 0 ? Colors.orange : Colors.green,
            duration: Duration(seconds: conflicts > 0 ? 4 : 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _events.removeWhere((e) => e.id == tempEvent.id);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add event: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
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
                Color(0xFF06B6D4),
                Color(0xFF22D3EE),
                Color(0xFF67E8F9),
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
                  color: Colors.white.withOpacity(0.1),
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
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEC4899).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => _buildBirthdaysDialog(),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.cake, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Upcoming Birthdays',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_upcomingBirthdays.length} ${_upcomingBirthdays.length == 1 ? 'birthday' : 'birthdays'} in the next 30 days',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                          ),
                        ),
                        if (_upcomingBirthdays.isNotEmpty) ...[
                          const SizedBox(height: 8),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.celebration, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              daysUntil == 0
                  ? '${nextBirthday.title} is TODAY! 🎉'
                  : '${nextBirthday.title} in $daysUntil ${daysUntil == 1 ? 'day' : 'days'}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
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
          Icon(Icons.cake, color: Color(0xFFEC4899)),
          SizedBox(width: 8),
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
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
                    ),
                    borderRadius: BorderRadius.circular(8),
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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF06B6D4), Color(0xFF22D3EE)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey.shade700,
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
        margin: const EdgeInsets.all(16),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
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
                colors: [Color(0xFF06B6D4), Color(0xFF22D3EE)],
              ),
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: const Color(0xFF06B6D4).withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            markerDecoration: const BoxDecoration(
              color: Color(0xFFEC4899),
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
              borderRadius: BorderRadius.circular(8),
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      sliver: SliverToBoxAdapter(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                DateFormat('EEEE, MMMM d, yyyy').format(_selectedDay),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (dayEvents.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: DesignTokens.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${dayEvents.length} ${dayEvents.length == 1 ? 'event' : 'events'}',
                  style: const TextStyle(
                    color: DesignTokens.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
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
        padding: const EdgeInsets.all(16.0),
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
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                _error!.replaceAll('Exception: ', ''),
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadEvents,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.primaryColor,
                ),
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
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'No events for this day',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
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
        padding: const EdgeInsets.all(16.0),
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
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                _error!.replaceAll('Exception: ', ''),
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadEvents,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.primaryColor,
                ),
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
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
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF06B6D4), Color(0xFF22D3EE)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              DateFormat('d').format(date),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              DateFormat('MMM').format(date).toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('EEEE').format(date),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              DateFormat('MMMM d, yyyy').format(date),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: DesignTokens.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${events.length}',
                          style: const TextStyle(
                            color: DesignTokens.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ...events.asMap().entries.map((entry) {
                  return _buildEventCard(entry.value, entry.key);
                }).toList(),
                const SizedBox(height: 8),
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
      duration: Duration(milliseconds: 300 + (index * 50)),
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
        margin: const EdgeInsets.only(bottom: 12),
        elevation: isBirthday ? 6 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isBirthday
              ? const BorderSide(color: Color(0xFFEC4899), width: 2)
              : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToEventDetail(event),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: isBirthday
                  ? LinearGradient(
                      colors: [
                        gradient[0].withOpacity(0.05),
                        gradient[1].withOpacity(0.05),
                      ],
                    )
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: gradient),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: gradient[0].withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(icon, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
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
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (event.recurrenceRule != null && event.recurrenceRule != 'none')
                                  Tooltip(
                                    message: _formatRecurrence(event.recurrenceRule!),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.blue.shade200),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.repeat, size: 12, color: Colors.blue.shade700),
                                          const SizedBox(width: 4),
                                          Text(
                                            _getRecurrenceShortForm(event.recurrenceRule!),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  event.isAllDay ? Icons.calendar_today : Icons.access_time,
                                  size: 14,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  event.isAllDay
                                      ? 'All Day'
                                      : DateFormat('h:mm a').format(event.startDate.toLocal()),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                if (event.endDate != null && !event.isAllDay) ...[
                                  Text(
                                    ' - ${DateFormat('h:mm a').format(event.endDate!.toLocal())}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
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
                    const SizedBox(height: 12),
                    Text(
                      event.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                  ],
                  if (event.location != null && event.location!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.location!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: gradient),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _formatEventType(event.eventType),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (event.attendeeIds.isNotEmpty)
                        Row(
                          children: [
                            Icon(Icons.people, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              '${event.attendeeIds.length}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      if (event.autoGenerated) ...[
                        const SizedBox(width: 8),
                        Tooltip(
                          message: 'Auto-generated from Family Tree',
                          child: Icon(
                            Icons.auto_awesome,
                            size: 16,
                            color: Colors.blue.shade400,
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
        return [const Color(0xFFEC4899), const Color(0xFFF472B6)];
      case 'death_anniversary':
        return [const Color(0xFF6B7280), const Color(0xFF9CA3AF)];
      case 'anniversary':
        return [const Color(0xFFDB2777), const Color(0xFFEC4899)];
      case 'gathering':
        return [const Color(0xFF7C3AED), const Color(0xFF9333EA)];
      case 'holiday':
        return [const Color(0xFFF59E0B), const Color(0xFFFBBF24)];
      case 'historical_event':
        return [const Color(0xFF92400E), const Color(0xFFA16207)];
      case 'reminder':
        return [const Color(0xFF10B981), const Color(0xFF34D399)];
      default:
        return [const Color(0xFF06B6D4), const Color(0xFF22D3EE)];
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
