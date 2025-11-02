import 'package:flutter/material.dart';
import '../../services/family/family_service.dart';
import '../../models/family/family_calendar.dart';
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
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final startDate = DateTime(_focusedDay.year, _focusedDay.month, 1);
      final endDate = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
      final events = await _familyService.getCalendarEvents(
        startDate: startDate,
        endDate: endDate,
      );
      setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUpcomingBirthdays() async {
    try {
      final birthdays = await _familyService.getUpcomingBirthdays(daysAhead: 30);
      setState(() {
        _upcomingBirthdays = birthdays;
      });
    } catch (e) {
      // Silently fail for birthdays
    }
  }

  Future<void> _refreshEvents() async {
    await Future.wait([
      _loadEvents(),
      _loadUpcomingBirthdays(),
    ]);
  }

  List<FamilyCalendarEvent> _getEventsForDay(DateTime day) {
    return _events.where((event) {
      return isSameDay(event.startDate, day) ||
          (event.endDate != null && 
           !day.isBefore(event.startDate) && 
           !day.isAfter(event.endDate!));
    }).toList();
  }

  List<FamilyCalendarEvent> _getAllUpcomingEvents() {
    final now = DateTime.now();
    return _events
        .where((event) => event.startDate.isAfter(now) || isSameDay(event.startDate, now))
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
    try {
      final result = await _familyService.createCalendarEvent(data);
      
      if (mounted) {
        // Check for conflicts
        final conflicts = result['data']?['conflicts'] ?? 0;
        final warning = result['data']?['conflict_warning'];
        
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
        _refreshEvents();
      }
    } catch (e) {
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
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              // Show all birthdays in a dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
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
                        return ListTile(
                          leading: const Icon(Icons.cake),
                          title: Text(birthday.title),
                          subtitle: Text(
                            DateFormat('MMMM d, yyyy').format(birthday.startDate),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _navigateToEventDetail(birthday);
                          },
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
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.cake, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Upcoming Birthdays',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_upcomingBirthdays.length} ${_upcomingBirthdays.length == 1 ? 'birthday' : 'birthdays'} in the next 30 days',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ),
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
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onFormatChanged: (format) {
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
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      sliver: SliverToBoxAdapter(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('EEEE, MMMM d').format(_selectedDay),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_getEventsForDay(_selectedDay).isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: DesignTokens.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_getEventsForDay(_selectedDay).length} ${_getEventsForDay(_selectedDay).length == 1 ? 'event' : 'events'}',
                  style: const TextStyle(
                    color: DesignTokens.primaryColor,
                    fontWeight: FontWeight.bold,
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
        child: EnhancedEmptyState(
          icon: Icons.event_busy,
          title: 'No Events',
          message: 'No events scheduled for this day.',
          actionLabel: 'Add Event',
          onAction: _showAddEventDialog,
          gradientColors: const [
            Color(0xFF06B6D4),
            Color(0xFF22D3EE),
          ],
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16.0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final event = dayEvents[index];
            return _buildEventCard(event);
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
          message: 'You have no upcoming events scheduled.',
          actionLabel: 'Add Event',
          onAction: _showAddEventDialog,
          gradientColors: const [
            Color(0xFF06B6D4),
            Color(0xFF22D3EE),
          ],
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16.0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final event = upcomingEvents[index];
            return _buildEventCard(event, showDate: true);
          },
          childCount: upcomingEvents.length,
        ),
      ),
    );
  }

  Widget _buildEventCard(FamilyCalendarEvent event, {bool showDate = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToEventDetail(event),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _getEventGradient(event.eventType),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('MMM').format(event.startDate),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      DateFormat('d').format(event.startDate),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (event.autoGenerated)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              Icons.auto_awesome,
                              size: 12,
                              color: Colors.blue.shade700,
                            ),
                          ),
                      ],
                    ),
                    if (event.description != null && event.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        event.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          event.isAllDay
                              ? 'All Day'
                              : DateFormat('h:mm a').format(event.startDate),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (event.location != null && event.location!.isNotEmpty) ...[
                          const SizedBox(width: 16),
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.location!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (event.recurrenceRule != null && event.recurrenceRule != 'none') ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.repeat,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatRecurrence(event.recurrenceRule!),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
              ),
            ],
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
      case 'meeting':
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

  String _formatRecurrence(String recurrence) {
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

class ShimmerEventCard extends StatelessWidget {
  const ShimmerEventCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            ShimmerLoading(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerLoading(
                    child: Container(
                      width: double.infinity,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ShimmerLoading(
                    child: Container(
                      width: 200,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
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
}
