import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../Authentication/User Information/user_details.dart';
import '../../Authentication/User Information/user_session.dart';
import '../../Configuration/ApiUrlConfig.dart';
import '../../Dependency_Injection/dependency_injection.dart';
import '../../SideMenuBar/screen/sidebar.dart';
import '../../dashboard/location_service.dart';
import '../../dashboard/screen/dashboard.dart';
import '../bloc/holiday_bloc.dart';
import '../holiday_card.dart';
import '../holiday_model.dart';

// A simple class to hold the color theme for each card
class HolidayCardTheme {
  final Color backgroundColor;
  final Color textColor;

  HolidayCardTheme({required this.backgroundColor, required this.textColor});
}

class HolidayListScreen extends StatefulWidget {
  const HolidayListScreen({super.key});

  @override
  State<HolidayListScreen> createState() => _HolidayListScreenState();
}

class _HolidayListScreenState extends State<HolidayListScreen> {
  // Define the color palette based on the UI design
  final List<HolidayCardTheme> _colorThemes = [
    HolidayCardTheme(
        backgroundColor: const Color(0xFFFDE7EA),
        textColor: const Color(0xFFE53935)), // Light Pink
    HolidayCardTheme(
        backgroundColor: const Color(0xFFE3F2FD),
        textColor: const Color(0xFF1E88E5)), // Light Blue
    HolidayCardTheme(
        backgroundColor: const Color(0xFFF3E5F5),
        textColor: const Color(0xFF8E24AA)), // Light Purple
    HolidayCardTheme(
        backgroundColor: const Color(0xFFFFF3E0),
        textColor: const Color(0xFFFB8C00)), // Light Orange
  ];

  // State variables for month-wise grouping and selection
  Map<String, List<HolidayModel>> _groupedHolidays = {};
  List<String> _availableMonths = [];
  String? _selectedMonth;

  @override
  void initState() {
    super.initState();
    // Fetch holidays when the screen is initialized
    getIt<HolidayBloc>().add(FetchHolidays());
  }

  // This method processes the raw holiday list into a grouped map
  void _processHolidays(List<HolidayModel> holidays) {
    // Return early if there's nothing to process.
    if (holidays.isEmpty) {
      // You could generate months for the current year here as a fallback if needed.
      // For now, we just clear the state.
      setState(() {
        _groupedHolidays = {};
        _availableMonths = [];
        _selectedMonth = null;
      });
      return;
    }

    // Sort holidays chronologically by the first date
    holidays.sort((a, b) {
      if (a.dates.isEmpty || b.dates.isEmpty) return 0;
      return a.dates.first.compareTo(b.dates.first);
    });

    final DateFormat monthKeyFormat = DateFormat('MMMM yyyy');
    final Map<String, List<HolidayModel>> grouped = {};

    // Group holidays by month, using the first date
    for (var holiday in holidays) {
      if (holiday.dates.isEmpty) continue;
      try {
        final date = DateFormat("yyyy-MM-dd").parse(holiday.dates.first);
        final monthKey = monthKeyFormat.format(date).toUpperCase();
        if (grouped[monthKey] == null) {
          grouped[monthKey] = [];
        }
        grouped[monthKey]!.add(holiday);
      } catch (e) {
        print(
            "Could not parse date for holiday: ${holiday.title}, dates: ${holiday.dates}");
      }
    }

    // --- NEW LOGIC ---
    // Determine the year from the first holiday's first date in the data
    int year = DateTime.now().year; // Fallback to current year
    if (holidays.isNotEmpty && holidays.first.dates.isNotEmpty) {
      try {
        year = DateFormat("yyyy-MM-dd").parse(holidays.first.dates.first).year;
      } catch (e) {
        print("Could not parse year from first holiday date.");
      }
    }

    // Generate a list of all 12 months for that year
    final List<String> allMonthsOfYear = List.generate(12, (index) {
      final monthDate = DateTime(year, index + 1); // index is 0-11, so add 1
      return monthKeyFormat.format(monthDate).toUpperCase();
    });
    // --- END OF NEW LOGIC ---

    setState(() {
      _groupedHolidays = grouped;
      // Use the newly generated list of all 12 months for the dropdown
      _availableMonths = allMonthsOfYear;

      // Set the current month as selected. Since it's August 2025, it will be selected.
      final currentMonthKey =
          monthKeyFormat.format(DateTime.now()).toUpperCase();
      if (_availableMonths.contains(currentMonthKey)) {
        _selectedMonth = currentMonthKey;
      } else if (_availableMonths.isNotEmpty) {
        // Fallback to the first month of the year if the current one isn't in the list
        _selectedMonth = _availableMonths.first;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: const Text(
          "Holiday List",
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black, size: 30),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (context) => HomeScreen(
                        userSession: getIt<UserSession>(),
                        userDetails: getIt<UserDetails>(),
                        apiUrlConfig: getIt<ApiUrlConfig>(),
                        locationService: getIt<LocationService>(),
                      )),
              (route) => false,
            );
          },
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              color: Colors.black,
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          ),
        ],
      ),
      drawer: const CustomSidebar(), // Use endDrawer for the hamburger menu
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Render the month selector dropdown
          _buildMonthSelector(),
          Expanded(
            child: BlocConsumer<HolidayBloc, HolidayState>(
              bloc: getIt<HolidayBloc>(),
              listener: (context, state) {
                // When holidays are loaded, process them for grouping
                if (state is HolidayLoaded && state.holidaysList.isNotEmpty) {
                  _processHolidays(state.holidaysList);
                }
              },
              builder: (context, state) {
                if (state is HolidayLoading || state is HolidayInitial) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is HolidayLoaded) {
                  // Get the holidays for the currently selected month
                  final holidaysForSelectedMonth =
                      _groupedHolidays[_selectedMonth] ?? [];

                  if (holidaysForSelectedMonth.isEmpty) {
                    return const Center(
                        child: Text("No holidays found for this month."));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 8.0),
                    itemCount: holidaysForSelectedMonth.length,
                    itemBuilder: (context, index) {
                      final holiday = holidaysForSelectedMonth[index];
                      // Cycle through the color themes
                      final theme = _colorThemes[index % _colorThemes.length];
                      return _TimelineTile(
                        holiday: holiday,
                        theme: theme,
                        isFirst: index == 0,
                        isLast: index == holidaysForSelectedMonth.length - 1,
                      );
                    },
                  );
                } else if (state is HolidayError) {
                  return Center(child: Text(state.errorMessage));
                }
                // Initial or empty state
                return const Center(
                    child: Text('Failed to fetch holidays data...'));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Padding(
      padding: const EdgeInsets.only(left: 35.0, top: 20.0, bottom: 10.0),
      child: Row(
        children: [
          // Leading dot for alignment with the timeline
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          // Dropdown for month selection
          if (_availableMonths.isNotEmpty && _selectedMonth != null)
            DropdownButton<String>(
              value: _selectedMonth,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedMonth = newValue;
                });
              },
              items: _availableMonths
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      fontFamily: 'Poppins',
                      color: Colors.black,
                    ),
                  ),
                );
              }).toList(),
              underline: Container(), // Hides the default underline
              icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
              style:
                  const TextStyle(color: Colors.black, fontFamily: 'Poppins'),
            )
          else
            // Show a placeholder while loading or if no months are available
            const Text(
              'LOADING MONTH...',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                fontFamily: 'Poppins',
                color: Colors.grey,
              ),
            ),
        ],
      ),
    );
  }
}

// Custom widget for the timeline entry
class _TimelineTile extends StatelessWidget {
  final HolidayModel holiday;
  final HolidayCardTheme theme;
  final bool isFirst;
  final bool isLast;

  const _TimelineTile({
    required this.holiday,
    required this.theme,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    // Input format from the API
    final DateFormat inputFormat = DateFormat("yyyy-MM-dd");
    // Desired output format for the card to match the screenshot
    final DateFormat dayFormat = DateFormat("dd");
    final DateFormat monthYearFormat = DateFormat("MMM, yyyy");
    String formattedDate =
        holiday.dates.join(', '); // Default to raw dates joined

    try {
      if (holiday.dates.isNotEmpty) {
        final parsedDates =
            holiday.dates.map((d) => inputFormat.parse(d)).toList();
        parsedDates.sort(); // Ensure sorted order
        final start = parsedDates.first;
        final end = parsedDates.last;

        if (start == end) {
          // Single day: "09 AUG, 2025"
          formattedDate = monthYearFormat
              .format(start)
              .replaceAll('MMM', DateFormat("MMM").format(start).toUpperCase());
          formattedDate = "${dayFormat.format(start)} $formattedDate";
        } else if (start.month == end.month && start.year == end.year) {
          // Same month/year: "23 - 24 SEP, 2025"
          formattedDate =
              "${dayFormat.format(start)} - ${dayFormat.format(end)} ${monthYearFormat.format(start).replaceAll('MMM', DateFormat("MMM").format(start).toUpperCase())}";
        } else {
          // Spanning months: "23 SEP, 2025 - 01 OCT, 2025"
          formattedDate =
              "${dayFormat.format(start)} ${monthYearFormat.format(start).replaceAll('MMM', DateFormat("MMM").format(start).toUpperCase())} - "
              "${dayFormat.format(end)} ${monthYearFormat.format(end).replaceAll('MMM', DateFormat("MMM").format(end).toUpperCase())}";
        }
      }
    } catch (e) {
      print(
          "Error parsing dates: ${holiday.dates}. Ensure they are in yyyy-MM-dd format.");
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTimelineConnector(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 20.0, bottom: 24.0),
              // Assuming your HolidayCard is set up correctly
              child: HolidayCard(
                title: holiday.title, // Maps from 'holiday_name'
                date: formattedDate,
                backgroundColor: theme.backgroundColor,
                textColor: theme.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineConnector() {
    return SizedBox(
      width: 50,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // The line above the dot
          Expanded(
            child: Container(
              width: 2,
              color: isFirst ? Colors.transparent : Colors.grey.shade300,
            ),
          ),
          // The dot
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade400, width: 2),
            ),
          ),
          // The line below the dot
          Expanded(
            child: Container(
              width: 2,
              color: isLast ? Colors.transparent : Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }
}
