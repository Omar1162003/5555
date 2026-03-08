import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/notification_service.dart';

class BookProvider extends ChangeNotifier {
  final NotificationService _notifications = NotificationService();

  static const int _checkoutDays = 14;

  /// Notification IDs are derived deterministically from the book id so they
  /// survive app restarts and are easy to cancel by id alone.
  int _confirmId(String bookId) => bookId.hashCode & 0x7FFFFFFF;
  int _reminderId(String bookId) => (_confirmId(bookId) + 1) & 0x7FFFFFFF;
  int _returnId(String bookId) => (_confirmId(bookId) + 2) & 0x7FFFFFFF;

  Future<void> onBookCheckedOut(Book book) async {
    final dueDate = DateTime.now().add(const Duration(days: _checkoutDays));
    final reminderDate = dueDate.subtract(const Duration(days: 1));

    await _notifications.showNotification(
      id: _confirmId(book.id),
      title: 'Book Borrowed ✅',
      body: '"${book.title}" is checked out. Due: ${_formatDate(dueDate)}.',
    );

    await _notifications.scheduleNotification(
      id: _reminderId(book.id),
      title: 'Book Due Soon 📅',
      body:
          '"${book.title}" must be returned tomorrow, ${_formatDate(dueDate)}.',
      scheduledTime: reminderDate,
    );
  }

  Future<void> onBookReturned(Book book) async {
    // Cancel the scheduled reminder since the book is already back.
    await _notifications.cancelNotification(_reminderId(book.id));

    await _notifications.showNotification(
      id: _returnId(book.id),
      title: 'Book Returned 📚',
      body: 'Thank you for returning "${book.title}".',
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
