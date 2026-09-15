import 'package:flutter/foundation.dart';

/// A fictional person in Halo.
@immutable
class Author {
  const Author({
    required this.name,
    required this.handle,
    required this.avatarUrl,
  });

  final String name;
  final String handle;
  final String avatarUrl;
}

/// A feed post.
///
/// All local and constant: no backend, and the feed never loads. The only
/// async state on the screen is each photo, handled in its own cell.
@immutable
class Post {
  const Post({
    required this.author,
    required this.photoUrl,
    required this.photoDescription,
    required this.place,
    required this.caption,
    required this.likes,
    required this.comments,
    required this.postedAgo,
    this.liked = false,
    this.saved = false,
  });

  final Author author;
  final String photoUrl;

  /// Photo description for screen readers. The photo is content, not
  /// decoration, so it says what it is (`icon-alt`).
  final String photoDescription;

  final String place;
  final String caption;
  final int likes;
  final int comments;

  /// Pre-formatted as relative time, which is all the mockup shows.
  final String postedAgo;

  final bool liked;
  final bool saved;

  Post copyWith({bool? liked, bool? saved, int? likes}) {
    return Post(
      author: author,
      photoUrl: photoUrl,
      photoDescription: photoDescription,
      place: place,
      caption: caption,
      likes: likes ?? this.likes,
      comments: comments,
      postedAgo: postedAgo,
      liked: liked ?? this.liked,
      saved: saved ?? this.saved,
    );
  }
}

/// A story in the horizontal rail.
@immutable
class Story {
  const Story({required this.author, required this.seen, this.isMine = false});

  final Author author;
  final bool seen;

  /// The rail's first item, which in the mockup is the user.
  final bool isMine;
}
