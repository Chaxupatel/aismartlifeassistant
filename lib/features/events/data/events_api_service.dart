import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../domain/event.dart';

/// Service class responsible for fetching real-world events from public APIs.
class EventsApiService {
  static const String _holidayUrl = 'https://date.nager.at/api/v3/NextPublicHolidaysWorldwide';
  static const String _cricketApiKey = 'b412baa5-0706-46ba-9f6c-4c2966a9b590';
  static const String _cricketUrl = 'https://api.cricapi.com/v1/matches';

  /// Fetches upcoming worldwide public holidays from the Nager.Date API.
  Future<List<Event>> fetchHolidays() async {
    try {
      debugPrint('EventsApiService: Fetching holidays from $_holidayUrl...');
      final response = await http.get(Uri.parse(_holidayUrl))
          .timeout(const Duration(seconds: 10));
      debugPrint('EventsApiService: Holidays response code: ${response.statusCode}');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        debugPrint('EventsApiService: Parsed ${data.length} holidays.');
        return data.map((json) {
          final dateStr = json['date'] as String;
          final name = json['name'] as String;
          final countryCode = json['countryCode'] as String;
          return Event(
            id: 'holiday_${dateStr}_$name',
            title: '$name ($countryCode)',
            dateTime: DateTime.parse(dateStr),
            location: 'Public Holiday in $countryCode',
            type: 'Holidays',
            icon: Icons.flag_rounded,
            color: Colors.greenAccent,
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('EventsApiService: Error fetching holidays: $e');
    }
    return [];
  }

  /// Fetches upcoming football matches (FIFA World Cup matches from openfootball JSON data).
  Future<List<Event>> fetchFootballMatches() async {
    try {
      debugPrint('EventsApiService: Fetching football matches...');
      final worldCupEvents = await _fetchWorldCupMatches();
      // Sort matches chronologically
      worldCupEvents.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      return worldCupEvents;
    } catch (e) {
      debugPrint('EventsApiService: General error fetching football matches: $e');
    }
    return [];
  }

  /// Fetches upcoming FIFA World Cup matches from openfootball JSON data.
  Future<List<Event>> _fetchWorldCupMatches() async {
    try {
      debugPrint('EventsApiService: Fetching FIFA World Cup matches from openfootball...');
      final response = await http.get(Uri.parse('https://raw.githubusercontent.com/openfootball/worldcup.json/master/2026/worldcup.json'))
          .timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List<dynamic>? matches = body['matches'];
        if (matches != null && matches.isNotEmpty) {
          final List<Event> events = [];
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          
          for (final match in matches) {
            final String dateStr = match['date'] as String? ?? '';
            if (dateStr.isEmpty) continue;
            
            final matchDate = DateTime.tryParse(dateStr) ?? DateTime.now();
            final targetDate = DateTime(matchDate.year, matchDate.month, matchDate.day);
            
            // Only show matches happening today or in the future
            if (targetDate.isBefore(today)) continue;
            
            final String team1 = match['team1'] as String? ?? 'TBD';
            final String team2 = match['team2'] as String? ?? 'TBD';
            final String round = match['round'] as String? ?? 'Group Stage';
            final String ground = match['ground'] as String? ?? 'World Cup Stadium';
            final String timeStr = match['time'] as String? ?? '';
            
            // Construct a title
            final String title = '[FIFA World Cup] $team1 vs $team2';
            
            final matchDateTime = _parseOpenFootballDateTime(dateStr, timeStr);
            
            events.add(Event(
              id: 'worldcup_${dateStr}_${team1}_$team2',
              title: title,
              dateTime: matchDateTime,
              location: '$ground ($round)',
              type: 'Football Matches',
              icon: Icons.sports_soccer_rounded,
              color: Colors.orangeAccent,
            ));
          }
          
          debugPrint('EventsApiService: Parsed ${events.length} upcoming World Cup matches.');
          return events;
        }
      }
    } catch (e) {
      debugPrint('EventsApiService: Error fetching World Cup matches: $e');
    }
    return [];
  }

  /// Fetches upcoming cricket matches from CricketData.org (CricAPI).
  /// Only returns matches that have NOT yet started or ended.
  Future<List<Event>> fetchCricketMatches() async {
    try {
      final url = '$_cricketUrl?apikey=$_cricketApiKey&offset=0';
      debugPrint('EventsApiService: Fetching cricket matches from CricAPI...');
      final response = await http.get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      debugPrint('EventsApiService: Cricket response code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final String status = body['status'] as String? ?? '';

        if (status == 'success') {
          final List<dynamic>? data = body['data'];
          if (data != null && data.isNotEmpty) {
            final now = DateTime.now();
            final List<Event> events = [];

            for (final match in data) {
              // Only include matches that haven't started yet
              final bool matchStarted = match['matchStarted'] == true;
              final bool matchEnded = match['matchEnded'] == true;
              if (matchEnded) continue; // Skip completed matches

              final String id = match['id'] as String? ?? '';
              final String name = match['name'] as String? ?? 'Unknown Match';
              final String matchStatus = match['status'] as String? ?? '';
              final String venue = match['venue'] as String? ?? 'TBD';
              final String dateStr = match['dateTimeGMT'] as String? ?? '';
              final String matchType = (match['matchType'] as String? ?? '').toUpperCase();

              // Parse the match date
              DateTime matchDateTime;
              if (dateStr.isNotEmpty) {
                matchDateTime = _parseCricApiDateTime(dateStr);
              } else {
                final String fallbackDate = match['date'] as String? ?? '';
                matchDateTime = fallbackDate.isNotEmpty
                    ? _parseCricApiDateTime(fallbackDate)
                    : now;
              }

              // Build a clean title from team names
              final List<dynamic>? teams = match['teams'] as List<dynamic>?;
              String title;
              if (teams != null && teams.length >= 2) {
                title = '${teams[0]} vs ${teams[1]}';
                if (matchType.isNotEmpty) {
                  title += ' ($matchType)';
                }
              } else {
                title = name;
              }

              // Use match status as subtitle location info
              String locationInfo = venue;
              if (matchStarted && !matchEnded && matchStatus.isNotEmpty) {
                locationInfo = '$venue • LIVE';
              }

              events.add(Event(
                id: 'cricket_$id',
                title: title,
                dateTime: matchDateTime,
                location: locationInfo,
                type: 'Cricket Matches',
                icon: Icons.sports_cricket_rounded,
                color: Colors.blueAccent,
              ));
            }

            debugPrint('EventsApiService: Loaded ${events.length} upcoming cricket matches.');
            return events;
          }
        }
      }
    } catch (e) {
      debugPrint('EventsApiService: Error fetching cricket matches: $e');
    }
    return [];
  }

  /// Parses GMT/UTC datetime from CricAPI (e.g. "2026-06-24 13:30:00") into local time.
  DateTime _parseCricApiDateTime(String dateStr) {
    if (dateStr.isEmpty) return DateTime.now();
    try {
      String formatted = dateStr.trim().replaceAll(' ', 'T');
      if (!formatted.endsWith('Z')) {
        formatted += 'Z';
      }
      return DateTime.tryParse(formatted)?.toLocal() ?? DateTime.now();
    } catch (e) {
      debugPrint('EventsApiService: Error parsing CricAPI datetime: $e');
    }
    return DateTime.tryParse(dateStr)?.toLocal() ?? DateTime.now();
  }



  /// Parses datetime with offset from openfootball (e.g. date="2026-06-24", time="12:00 UTC-7") into local time.
  DateTime _parseOpenFootballDateTime(String dateStr, String timeStr) {
    if (dateStr.isEmpty) return DateTime.now();
    if (timeStr.isEmpty) {
      return DateTime.tryParse(dateStr)?.toLocal() ?? DateTime.now();
    }
    
    try {
      final parts = timeStr.trim().split(RegExp(r'\s+'));
      final mainTime = parts[0]; // e.g. "12:00"
      
      String offsetStr = 'Z'; // default to UTC/Z
      if (parts.length > 1) {
        final utcOffset = parts[1]; // e.g. "UTC-7"
        final cleanOffset = utcOffset.replaceAll('UTC', '').trim(); // e.g. "-7"
        if (cleanOffset.isNotEmpty) {
          final isNegative = cleanOffset.startsWith('-');
          final numberPart = cleanOffset.substring(1); // e.g. "7"
          final int? hours = int.tryParse(numberPart);
          if (hours != null) {
            final paddedHours = hours.toString().padLeft(2, '0');
            final sign = isNegative ? '-' : '+';
            offsetStr = '$sign$paddedHours:00'; // e.g. "-07:00"
          }
        }
      }
      
      final isoStr = '${dateStr}T$mainTime:00$offsetStr';
      return DateTime.tryParse(isoStr)?.toLocal() ?? DateTime.tryParse(dateStr)?.toLocal() ?? DateTime.now();
    } catch (e) {
      debugPrint('EventsApiService: Error parsing openfootball datetime: $e');
    }
    return DateTime.tryParse(dateStr)?.toLocal() ?? DateTime.now();
  }
}
