import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/event.dart';

/// Notifier class managing the list of life events, social gatherings, and milestones in memory.
class EventsNotifier extends Notifier<List<Event>> {
  @override
  List<Event> build() {
    final now = DateTime.now();
    return [
      // Cricket Matches
      Event(
        id: 'c1',
        title: 'IPL Final: MI vs CSK Showdown',
        dateTime: DateTime(now.year, now.month, now.day + 2, 19, 30),
        location: 'Wankhede Stadium, Mumbai',
        type: 'Cricket Matches',
        icon: Icons.sports_cricket_rounded,
        color: Colors.blueAccent,
      ),
      Event(
        id: 'c2',
        title: 'India vs Australia T20 International',
        dateTime: DateTime(now.year, now.month, now.day + 9, 15, 0),
        location: 'Narendra Modi Stadium, Ahmedabad',
        type: 'Cricket Matches',
        icon: Icons.sports_cricket_rounded,
        color: Colors.amberAccent,
      ),

      // Movies
      Event(
        id: 'm1',
        title: 'Spider-Man: Beyond the Spider-Verse',
        dateTime: DateTime(now.year, now.month, now.day + 7, 18, 0),
        location: 'IMAX Theater Mall of India',
        type: 'Movies',
        icon: Icons.movie_creation_rounded,
        color: Colors.tealAccent,
      ),
      Event(
        id: 'm2',
        title: 'Christopher Nolan\'s Next Sci-Fi Debut',
        dateTime: DateTime(now.year, now.month, now.day + 28, 20, 30),
        location: 'PVR Director\'s Cut, Delhi',
        type: 'Movies',
        icon: Icons.movie_filter_rounded,
        color: Colors.purpleAccent,
      ),

      // OTT Releases
      Event(
        id: 'o1',
        title: 'Stranger Things Season 5 (Netflix)',
        dateTime: DateTime(now.year, now.month, now.day + 12, 12, 30),
        location: 'Netflix Global Streaming',
        type: 'OTT Releases',
        icon: Icons.live_tv_rounded,
        color: Colors.redAccent,
      ),
      Event(
        id: 'o2',
        title: 'The Boys Season 5 Launch (Amazon Prime)',
        dateTime: DateTime(now.year, now.month, now.day + 6, 9, 0),
        location: 'Amazon Prime Streaming',
        type: 'OTT Releases',
        icon: Icons.tv_rounded,
        color: Colors.cyanAccent,
      ),

      // Birthdays
      Event(
        id: 'b1',
        title: 'Mom\'s 50th Golden Jubilee Birthday',
        dateTime: DateTime(now.year, now.month, now.day + 1, 19, 0),
        location: 'Grand Horizon Cafe Lounge',
        type: 'Birthdays',
        icon: Icons.cake_rounded,
        color: Colors.pinkAccent,
      ),
      Event(
        id: 'b2',
        title: 'Sarah\'s Surprise Birthday Barbecue',
        dateTime: DateTime(now.year, now.month, now.day + 15, 18, 30),
        location: 'Sarah\'s Backyard Garden',
        type: 'Birthdays',
        icon: Icons.celebration_rounded,
        color: Colors.deepOrangeAccent,
      ),

      // Holidays
      Event(
        id: 'h1',
        title: 'World Music Day public holiday',
        dateTime: DateTime(now.year, now.month, now.day + 2, 0, 0),
        location: 'National Festival Day',
        type: 'Holidays',
        icon: Icons.brightness_7_rounded,
        color: Colors.orangeAccent,
      ),
      Event(
        id: 'h2',
        title: 'Independence Day public holiday',
        dateTime: DateTime(now.year, now.month, now.day + 15, 0, 0),
        location: 'Federal Public Holiday',
        type: 'Holidays',
        icon: Icons.flag_rounded,
        color: Colors.greenAccent,
      ),
    ];
  }

  void addEvent(Event event) {
    state = [...state, event];
  }
}

/// Provider exposing the list of events.
final eventsProvider = NotifierProvider<EventsNotifier, List<Event>>(EventsNotifier.new);
