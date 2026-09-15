Stack: flutter

Escolhido pela recomendação do `flow/init.md`, sem restrição que a movesse: o
projeto nasceu vazio e precisa de um shader GLSL rodando sobre a árvore de
widgets em Android, iOS e web com um único pipeline de render. Flutter desenha
os próprios widgets, então o snapshot que alimenta o shader é idêntico nas três
plataformas — que é exatamente a premissa do efeito.

## Versões

- Flutter 3.41.1 (stable), Dart 3.11.0
- Plataforma: **android apenas**, por decisão do dono do projeto. Sem `ios/`,
  sem `web/`, sem `test/`.
- Renderizador: Impeller

## Dependências e por que existem

| Pacote | Papel |
|---|---|
| `sensors_plus` | acelerômetro, bruto e sem gravidade, fonte do ângulo |
| `flutter_shaders` | `AnimatedSampler`, entrega a subárvore renderizada ao shader como `ui.Image` sem congelar a interação |
| `cached_network_image` | fotos do Unsplash com placeholder, erro e cache em disco (`list-images`, `perf-decode`) |

Nenhuma biblioteca de UI de terceiros. Material 3 do SDK, tema próprio.

## Primitivas

- Tokens: `lib/theme/halo_theme.dart`. Cores por papel via
  `Theme.of(context).colorScheme`, texto via `Theme.of(context).textTheme`,
  espaçamento via `HaloSpacing`, raios via `HaloRadius`. Um valor cru onde
  existe token é defeito.
- Navegação: uma tela só. A `NavigationBar` inferior do mockup é decorativa e
  declarada como tal (`PRODUCT.md`), não é navegação real.
- Shader: `shaders/duo_fold.frag`, declarado em `pubspec.yaml` sob `shaders:`,
  carregado em `lib/duo/duo_shader.dart`.

## Contrato do shader

Os floats vão na ordem dos índices e mudá-la quebra o efeito em silêncio:

| Índice | Uniform | Unidade |
|---|---|---|
| 0, 1 | `uSize` (x, y) | pixels lógicos |
| 2 | `uTiltDegrees` | graus, ±80 |
| 3 | `uEyeDistancePx` | pixels lógicos (2.4 × largura) |
| 4 | `uBlurSpread` | px de raio por px de afastamento |
| 5 | `uDarkening` | fração de luz por px de raio |
| 6 | `uCornerRadius` | pixels lógicos, máximo |
| 7 | `uRimLight` | 0..1 |
| 8 | `uSpreadWidth` | pixels lógicos |
| 9 | `uSpreadStrength` | 0..1 |

O lado da dobradiça não é um uniform: sai do sinal de `uTiltDegrees`.

`uTexture` é sampler 0. Rotação em zero faz bypass pixel-perfect no shader, e o
Dart também descarta o `AnimatedSampler` nesse estado, para não pagar o
snapshot por frame com a tela parada (`perf-overdraw`).

O modelo: o painel da UI gira numa aresta vertical, a aresta livre se afasta do
observador, e a projeção o transforma num quadrilátero de cantos arredondados.
Fora dele é fundo preto. Um lado dobra de cada vez.

## Pisos de plataforma

- Android: minSdk padrão do Flutter. Nenhum `uses-feature` declarado como
  required — o app roda sem acelerômetro, caindo no controle manual
  (`sense-absent`).
- Amostragem a 50 Hz (`SensorInterval.gameInterval`), bem abaixo do teto de
  200 Hz que o Android 12 impõe a um listener sem a permissão de alta taxa.
- O sensor é assinado na primeira tela, não atrás de um toque: o efeito é o
  produto, e escondê-lo faria a primeira tela ser a menos interessante que o app
  tem. É solto assim que o app sai de primeiro plano.
- Offline: as fotos falham individualmente com estado próprio na célula. O
  efeito de dobra não depende de rede.

## Exceções deliberadas

- **`layout-orientation` (2026-09-11).** O app trava em retrato. O movimento é
  a entrada primária e a rotação automática competiria com ele: o aparelho
  giraria a UI no meio do gesto. Registrado como decisão, não como omissão.
- **`layout-chrome` (2026-09-12).** O app roda em `immersiveSticky`, sem barra
  de status nem de navegação. O efeito acontece nas bordas da tela, e duas
  faixas do sistema por cima delas escondem exatamente a parte que importa.
  `immersiveSticky` devolve as barras num deslize e as retira sozinho, então
  nada fica inalcançável — o que seria uma violação, e não uma exceção.
- **`nav-*` não se aplica (2026-09-11).** Uma tela, sem hierarquia. A barra
  inferior é cenário do mockup, com uma exceção: o perfil abre os ajustes.
