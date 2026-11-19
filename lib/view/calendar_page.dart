import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../controllers/library_controller.dart';
import '../model/diary_model.dart';
import '../theme/app_theme.dart';
import 'diary_page.dart';
import 'diary_form_page.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key, required this.controller});
  final LibraryController controller;
  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focused = DateTime.now(), _selected = DateTime.now();
  List<DiaryEntry> _events(DateTime date) => widget.controller.diary
      .where((e) => isSameDay(e.eventDate, date))
      .toList();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Seu calendário')),
    floatingActionButton: FloatingActionButton(
      tooltip: 'Registrar na data selecionada',
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) =>
              DiaryFormPage(controller: widget.controller, date: _selected),
        ),
      ),
      child: const Icon(Icons.add),
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: [
        TableCalendar<DiaryEntry>(
          locale: 'pt_BR',
          firstDay: DateTime(1900),
          lastDay: DateTime(2100, 12, 31),
          focusedDay: _focused,
          calendarFormat: CalendarFormat.month,
          availableCalendarFormats: const {CalendarFormat.month: 'Mês'},
          selectedDayPredicate: (day) => isSameDay(day, _selected),
          onDaySelected: (selected, focused) => setState(() {
            _selected = selected;
            _focused = focused;
          }),
          onPageChanged: (focused) => setState(() => _focused = focused),
          eventLoader: _events,
          startingDayOfWeek: StartingDayOfWeek.monday,
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
          calendarStyle: const CalendarStyle(
            outsideDaysVisible: false,
            selectedDecoration: BoxDecoration(
              color: AppTheme.wine,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: Color(0xFF351B32),
              shape: BoxShape.circle,
            ),
            markerDecoration: BoxDecoration(
              color: AppTheme.gold,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          DateFormat("dd 'de' MMMM", 'pt_BR').format(_selected),
          style: const TextStyle(fontSize: 23),
        ),
        const SizedBox(height: 14),
        if (_events(_selected).isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'Nenhuma experiência nesta data. Toque em + para registrar.',
              style: TextStyle(color: Colors.white60),
            ),
          ),
        ..._events(_selected)
            .map((e) => DiaryTile(entry: e, controller: widget.controller)),
      ],
    ),
  );
}
