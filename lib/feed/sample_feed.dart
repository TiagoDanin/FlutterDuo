import 'post.dart';

/// Monta a URL de uma foto do Unsplash no tamanho pedido.
///
/// O parâmetro de largura importa: sem ele o Unsplash entrega o original, e
/// `perf-decode` cobra a imagem pelo tamanho decodificado, não pelo tamanho do
/// arquivo. Uma foto de 4000 px num card de 400 custa cem vezes mais memória
/// do que precisa.
String _unsplash(String id, {required int width}) =>
    'https://images.unsplash.com/photo-$id?w=$width&q=80&auto=format&fit=crop';

const int _photoWidth = 900;
const int _avatarWidth = 160;

abstract final class HaloAuthors {
  static const mine = Author(
    name: 'Você',
    handle: 'voce',
    avatarUrl: '1517841905240-472988babdf9',
  );

  static const ana = Author(
    name: 'Ana',
    handle: 'ana',
    avatarUrl: '1494790108377-be9c29b29330',
  );

  static const joao = Author(
    name: 'João',
    handle: 'joao',
    avatarUrl: '1500648767791-00dcc994a43e',
  );

  static const paulo = Author(
    name: 'Paulo',
    handle: 'paulo',
    avatarUrl: '1506794778202-cad84cf45f1d',
  );

  static const maria = Author(
    name: 'Maria',
    handle: 'maria',
    avatarUrl: '1534528741775-53994a69daeb',
  );
}

/// O feed do mockup. Três posts: o bastante para haver rolagem real sob o
/// vidro, pouco o bastante para o app não virar uma galeria.
abstract final class SampleFeed {
  static List<Post> posts() => [
    Post(
      author: HaloAuthors.ana,
      photoUrl: _unsplash('1469474968028-56623f02e42e', width: _photoWidth),
      photoDescription:
          'Montanha com um feixe de luz do sol atravessando as nuvens',
      place: 'Serra do Cipó, MG',
      caption:
          'Subi às quatro da manhã só por causa desses dez minutos de luz. '
          'Valeu cada passo.',
      likes: 1284,
      comments: 47,
      postedAgo: '2 h',
    ),
    Post(
      author: HaloAuthors.joao,
      photoUrl: _unsplash('1518837695005-2083093ee35b', width: _photoWidth),
      photoDescription: 'Onda quebrando em mar aberto, vista de cima',
      place: 'Fernando de Noronha, PE',
      caption: 'O mar não pede licença.',
      likes: 892,
      comments: 23,
      postedAgo: '5 h',
      liked: true,
    ),
    Post(
      author: HaloAuthors.paulo,
      photoUrl: _unsplash('1433086966358-54859d0ed716', width: _photoWidth),
      photoDescription:
          'Cachoeira alta correndo sob uma ponte de pedra em meio à mata',
      place: 'Chapada Diamantina, BA',
      caption: 'Três horas de trilha para chegar aqui. Voltaria amanhã.',
      likes: 3410,
      comments: 158,
      postedAgo: '14 h',
      saved: true,
    ),
  ];

  static List<Story> stories() => const [
    Story(author: HaloAuthors.mine, seen: false, isMine: true),
    Story(author: HaloAuthors.ana, seen: false),
    Story(author: HaloAuthors.joao, seen: false),
    Story(author: HaloAuthors.maria, seen: false),
    Story(author: HaloAuthors.paulo, seen: true),
  ];

  static String avatarUrl(Author author) =>
      _unsplash(author.avatarUrl, width: _avatarWidth);
}
