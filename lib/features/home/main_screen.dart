import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_service.dart';
import '../../models/book.dart';
import '../../models/user.dart';
import '../../providers/book_provider.dart';
import 'home_tab.dart';
import 'search_tab.dart';
import 'my_books_tab.dart';
import '../profile/profile_tab.dart';

class MainScreen extends StatefulWidget {
  final User user;

  const MainScreen({super.key, required this.user});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  List<Book> _books = [];
  bool _isLoading = true;
  String? _loadError;

  final Set<String> _checkedOutBookIds = {};
  final Set<String> _favoriteBookIds = {};

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final books = await ApiService.getBooks();
      if (mounted) {
        setState(() {
          _books = books;
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _loadError = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = 'Failed to load books. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  List<Book> get _checkedOutBooks =>
      _books.where((book) => _checkedOutBookIds.contains(book.id)).toList();

  Future<void> _checkoutBook(Book book) async {
    // Capture provider before any awaits to avoid use_build_context_synchronously.
    final bookProvider = context.read<BookProvider>();
    try {
      await ApiService.checkoutBook(widget.user.id, book.id);
      setState(() {
        if (book.availableCopies > 0) {
          book.availableCopies--;
          _checkedOutBookIds.add(book.id);
        }
      });
      // Fire checkout confirmation + schedule due-date reminder notification.
      await bookProvider.onBookCheckedOut(book);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Checked out "${book.title}"'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _returnBook(String bookId) async {
    final book = _books.firstWhere((b) => b.id == bookId);
    // Capture provider before any awaits to avoid use_build_context_synchronously.
    final bookProvider = context.read<BookProvider>();
    try {
      await ApiService.returnBook(widget.user.id, bookId);
      setState(() {
        book.availableCopies++;
        _checkedOutBookIds.remove(bookId);
      });
      // Cancel pending due-date reminder and fire return confirmation notification.
      await bookProvider.onBookReturned(book);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Returned "${book.title}"'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _toggleFavorite(String bookId) {
    setState(() {
      if (_favoriteBookIds.contains(bookId)) {
        _favoriteBookIds.remove(bookId);
      } else {
        _favoriteBookIds.add(bookId);
      }
    });
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded,
                size: 64,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              _loadError!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadBooks,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final screens = [
      HomeTab(
        books: _books,
        user: widget.user,
        checkedOutBookIds: _checkedOutBookIds,
        favoriteBookIds: _favoriteBookIds,
        onCheckout: _checkoutBook,
        onToggleFavorite: _toggleFavorite,
      ),
      SearchTab(
        books: _books,
        checkedOutBookIds: _checkedOutBookIds,
        onCheckout: _checkoutBook,
      ),
      MyBooksTab(
        checkedOutBooks: _checkedOutBooks,
        onReturn: _returnBook,
      ),
      ProfileTab(
        user: widget.user,
        checkedOutCount: _checkedOutBookIds.length,
      ),
    ];

    return IndexedStack(
      index: _currentIndex,
      children: screens,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: (_isLoading || _loadError != null)
          ? null
          : BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search),
                  label: 'Search',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.book_outlined),
                  activeIcon: Icon(Icons.book),
                  label: 'My Books',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
    );
  }
}
