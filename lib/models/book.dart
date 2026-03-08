class Book {
  final String id;
  final String title;
  final String author;
  final String isbn;
  final String category;
  final String description;
  final String coverImage;
  final int publishYear;
  int availableCopies;
  final int totalCopies;
  final double rating;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.isbn,
    required this.category,
    required this.description,
    required this.coverImage,
    required this.publishYear,
    required this.availableCopies,
    required this.totalCopies,
    required this.rating,
  });

  bool get isAvailable => availableCopies > 0;

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      author: json['author']?.toString() ?? '',
      isbn: json['isbn']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      coverImage: json['coverImage']?.toString() ?? '',
      publishYear: (json['publishYear'] as num?)?.toInt() ?? 0,
      availableCopies: (json['availableCopies'] as num?)?.toInt() ?? 0,
      totalCopies: (json['totalCopies'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'isbn': isbn,
      'category': category,
      'description': description,
      'coverImage': coverImage,
      'publishYear': publishYear,
      'availableCopies': availableCopies,
      'totalCopies': totalCopies,
      'rating': rating,
    };
  }
}