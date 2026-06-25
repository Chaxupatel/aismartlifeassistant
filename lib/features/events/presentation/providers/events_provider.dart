import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/event.dart';
import '../../data/events_api_service.dart';

/// Notifier class managing the loading state of events.
class EventsLoadingNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void setLoading(bool loading) {
    state = loading;
  }
}

/// Provider exposing the loading state of the events fetch operation.
final eventsLoadingProvider = NotifierProvider<EventsLoadingNotifier, bool>(EventsLoadingNotifier.new);

/// Notifier class managing the list of real-world events fetched from public APIs.
class EventsNotifier extends Notifier<List<Event>> {
  final EventsApiService _apiService = EventsApiService();

  @override
  List<Event> build() {
    // Asynchronously fetch real events after the build phase is complete
    Future.microtask(() => _fetchRealEvents());

    return []; // Return empty list initially
  }

  Future<void> _fetchRealEvents() async {
    try {
      debugPrint('EventsNotifier: Starting incremental real-world events fetch...');
      
      // Ensure the loading state is active
      ref.read(eventsLoadingProvider.notifier).setLoading(true);
      
      int completedRequests = 0;
      void checkCompletion() {
        completedRequests++;
        if (completedRequests == 3) {
          ref.read(eventsLoadingProvider.notifier).setLoading(false);
          debugPrint('EventsNotifier: Fetch complete. Final count: ${state.length}');
        }
      }

      // Fetch each API independently with a timeout
      _apiService.fetchHolidays().timeout(const Duration(seconds: 4)).then((events) {
        if (events.isNotEmpty) {
          state = [...state, ...events]..sort((a, b) => a.dateTime.compareTo(b.dateTime));
          debugPrint('EventsNotifier: Loaded ${events.length} holidays.');
        }
        checkCompletion();
      }).catchError((e) {
        debugPrint('EventsNotifier: Error/Timeout fetching holidays: $e');
        checkCompletion();
      });

      _apiService.fetchFootballMatches().timeout(const Duration(seconds: 15)).then((events) {
        if (events.isNotEmpty) {
          state = [...state, ...events]..sort((a, b) => a.dateTime.compareTo(b.dateTime));
          debugPrint('EventsNotifier: Loaded ${events.length} football matches.');
        }
        checkCompletion();
      }).catchError((e) {
        debugPrint('EventsNotifier: Error/Timeout fetching football matches: $e');
        checkCompletion();
      });

      _apiService.fetchCricketMatches().timeout(const Duration(seconds: 8)).then((events) {
        if (events.isNotEmpty) {
          state = [...state, ...events]..sort((a, b) => a.dateTime.compareTo(b.dateTime));
          debugPrint('EventsNotifier: Loaded ${events.length} cricket matches.');
        }
        checkCompletion();
      }).catchError((e) {
        debugPrint('EventsNotifier: Error/Timeout fetching cricket matches: $e');
        checkCompletion();
      });

    } catch (e) {
      ref.read(eventsLoadingProvider.notifier).setLoading(false);
      debugPrint('EventsNotifier: Failed to initiate events fetch: $e');
    }
  }

  void addEvent(Event event) {
    state = [...state, event];
  }
}

/// Provider exposing the list of events.
final eventsProvider = NotifierProvider<EventsNotifier, List<Event>>(EventsNotifier.new);
