import 'package:flutter/material.dart';
import '../../models/book.dart';
import '../../models/user.dart';
import '../../widgets/book_details_sheet.dart';
import '../../widgets/mobile_book_card.dart';

class HomeTab extends StatelessWidget {
  final List<Book> books;
  final User user;
  final Set<String> checkedOutBookIds;
  final Set<String> favoriteBookIds;
  final Function(Book) onCheckout;
  final Function(String) onToggleFavorite;

  const HomeTab({
    super.key,
    required this.books,
    required this.user,
    required this.checkedOutBookIds,
    required this.favoriteBookIds,
    required this.onCheckout,
    required this.onToggleFavorite,
  });

  void _showBookDetails(BuildContext context, Book book) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BookDetailsSheet(
        book: book,
        isCheckedOut: checkedOutBookIds.contains(book.id),
        isFavorite: favoriteBookIds.contains(book.id),
        onCheckout: () {
          Navigator.pop(context);
          onCheckout(book);
        },
        onToggleFavorite: () => onToggleFavorite(book.id),
      ),
    );
  }

  List<Book> _getRecommendedBooks() {
    final userCategories = <String>{};
    for (final bookId in [...checkedOutBookIds, ...favoriteBookIds]) {
      final book =
          books.firstWhere((b) => b.id == bookId, orElse: () => books.first);
      userCategories.add(book.category);
    }

    if (userCategories.isEmpty) {
      return ([...books]..sort((a, b) => b.rating.compareTo(a.rating)))
          .take(4)
          .toList();
    }

    final recommendations = books.where((book) {
      return userCategories.contains(book.category) &&
          !checkedOutBookIds.contains(book.id) &&
          !favoriteBookIds.contains(book.id) &&
          book.isAvailable;
    }).toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));

    if (recommendations.length < 4) {
      final others = books.where((book) {
        return !checkedOutBookIds.contains(book.id) &&
            !favoriteBookIds.contains(book.id) &&
            book.isAvailable &&
            !recommendations.contains(book);
      }).toList()
        ..sort((a, b) => b.rating.compareTo(a.rating));
      recommendations.addAll(others.take(4 - recommendations.length));
    }

    return recommendations.take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    final topRated = ([...books]..sort((a, b) => b.rating.compareTo(a.rating)))
        .take(5)
        .toList();
    final popular = books
        .where((b) => b.availableCopies > 0 && b.availableCopies < 3)
        .take(4)
        .toList();
    final recent =
        ([...books]..sort((a, b) => b.publishYear.compareTo(a.publishYear)))
            .take(4)
            .toList();
    final recommended = _getRecommendedBooks();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).appBarTheme.backgroundColor,
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: colorScheme.primary,
                      child: Text(
                        user.initials,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, ${user.firstName}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'What will you read today?',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                          ),
                        ],
                      ),
                    ),
                    if (checkedOutBookIds.isNotEmpty)
                      Badge(
                        label: Text('${checkedOutBookIds.length}'),
                        child: const Icon(Icons.notifications_outlined),
                      ),
                  ],
                ),
              ),
            ),

            // Hero Banner
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.trending_up,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: const Text(
                            'Featured',
                            style:
                                TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Discover Amazing Books',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Browse our collection of ${books.length} books across multiple genres',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            _buildSectionHeader(
                context, Icons.star, Colors.amber.shade700, 'Top Rated'),
            _buildBookList(context, topRated),

            if (popular.isNotEmpty) ...[
              _buildSectionHeader(context, Icons.local_fire_department,
                  Colors.orange.shade700, 'Popular Now'),
              _buildBookList(context, popular),
            ],

            _buildSectionHeader(
                context, Icons.recommend, Colors.blue.shade700, 'Recommended for You'),
            _buildBookList(context, recommended),

            _buildSectionHeader(
                context, Icons.schedule, Colors.green.shade700, 'Recent Additions'),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: MobileBookCard(
                      book: recent[index],
                      isCheckedOut: checkedOutBookIds.contains(recent[index].id),
                      isFavorite: favoriteBookIds.contains(recent[index].id),
                      onTap: () => _showBookDetails(context, recent[index]),
                    ),
                  ),
                  childCount: recent.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildSectionHeader(
      BuildContext context, IconData icon, Color iconColor, String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  SliverPadding _buildBookList(BuildContext context, List<Book> bookList) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: MobileBookCard(
              book: bookList[index],
              isCheckedOut: checkedOutBookIds.contains(bookList[index].id),
              isFavorite: favoriteBookIds.contains(bookList[index].id),
              onTap: () => _showBookDetails(context, bookList[index]),
            ),
          ),
          childCount: bookList.length,
        ),
      ),
    );
  }
}
