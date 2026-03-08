import 'package:flutter/material.dart';
import '../services/notification_service.dart';

/// Model for a room booking, used internally by [RoomProvider].
class RoomBooking {
  final String id;
  final String roomId;
  final String roomName;
  final String userId;
  final String userName;
  final DateTime startTime;
  final DateTime endTime;

  const RoomBooking({
    required this.id,
    required this.roomId,
    required this.roomName,
    required this.userId,
    required this.userName,
    required this.startTime,
    required this.endTime,
  });
}

/// Manages study-room booking state and related notifications.
///
/// No room UI exists in this codebase yet; this provider is ready to be
/// consumed by a future RoomsTab / BookingScreen without any changes here.
class RoomProvider extends ChangeNotifier {
  final NotificationService _notifications = NotificationService();

  final List<RoomBooking> _bookings = [];

  List<RoomBooking> get bookings => List.unmodifiable(_bookings);

  // --- Notification ID helpers ---
  int _confirmId(String bookingId) => bookingId.hashCode & 0x7FFFFFFF;
  int _reminderId(String bookingId) => (_confirmId(bookingId) + 1) & 0x7FFFFFFF;
  int _cancelId(String bookingId) => (_confirmId(bookingId) + 2) & 0x7FFFFFFF;

  /// Book a room: persists the booking, fires a confirmation notification, and
  /// schedules a 30-minute reminder before [startTime].
  Future<bool> bookRoom({
    required String roomId,
    required String roomName,
    required String userId,
    required String userName,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final booking = RoomBooking(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      roomId: roomId,
      roomName: roomName,
      userId: userId,
      userName: userName,
      startTime: startTime,
      endTime: endTime,
    );

    _bookings.add(booking);
    notifyListeners();

    // 1. Instant confirmation
    await _notifications.showNotification(
      id: _confirmId(booking.id),
      title: 'Room Booked ✅',
      body: '$roomName reserved from ${_formatTime(startTime)} to ${_formatTime(endTime)}.',
    );

    // 2. Scheduled 30-min reminder (skipped silently if start is <30 min away)
    final reminderTime = startTime.subtract(const Duration(minutes: 30));
    await _notifications.scheduleNotification(
      id: _reminderId(booking.id),
      title: 'Room Booking Reminder ⏰',
      body: 'Your $roomName session starts in 30 minutes.',
      scheduledTime: reminderTime,
    );

    return true;
  }

  /// Cancel a booking: removes it, cancels the pending reminder, and fires a
  /// cancellation confirmation.
  Future<bool> cancelBooking(String bookingId) async {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index == -1) return false;

    final booking = _bookings[index];
    _bookings.removeAt(index);
    notifyListeners();

    // Cancel the 30-min reminder if it hasn't fired yet.
    await _notifications.cancelNotification(_reminderId(bookingId));

    // Cancellation confirmation
    await _notifications.showNotification(
      id: _cancelId(bookingId),
      title: 'Booking Cancelled ❌',
      body: 'Your reservation for ${booking.roomName} has been cancelled.',
    );

    return true;
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}
