import 'package:flutter/foundation.dart';

/// Uma pessoa fictícia do Halo.
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

/// Um post do feed.
///
/// Tudo aqui é local e constante: não há backend, e o feed nunca carrega. O
/// único estado assíncrono da tela é o de cada foto, tratado na célula.
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

  /// Descrição da foto para leitor de tela. A foto é conteúdo, não decoração,
  /// então ela diz o que é (`icon-alt`).
  final String photoDescription;

  final String place;
  final String caption;
  final int likes;
  final int comments;

  /// Já formatado em relativo, porque é assim que o mockup mostra.
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

/// Um story do trilho horizontal.
@immutable
class Story {
  const Story({required this.author, required this.seen, this.isMine = false});

  final Author author;
  final bool seen;

  /// O primeiro item do trilho, que no mockup é o próprio usuário.
  final bool isMine;
}
