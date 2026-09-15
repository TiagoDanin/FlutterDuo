# FlutterDuo — Halo

O *iPhone Duo effect* em Flutter: um fragment shader GLSL curva a interface real
em perspectiva, e o progresso vem da **inclinação física do aparelho**.

Deitado na mesa com a tela para cima, a tela fica plana. Levantar o aparelho
fecha a dobra.

O conteúdo dobrado é **Halo**, um mockup de rede social de fotografia que não
existe, com fotos do Unsplash. Ele está lá porque um retângulo colorido não
revela nada sobre o efeito: é preciso texto pequeno ao lado de foto grande,
avatar redondo e chrome fixo para ver o que a reprojeção faz.

## O efeito

Não há dobradiça no meio da tela. O conteúdo fica plano e nítido numa faixa
central, e são as **bordas de cima e de baixo** que tombam para trás — borrando,
escurecendo e se dissolvendo no void conforme se afastam do centro.

`shaders/duo_fold.frag` faz, numa passada:

| Camada | O que faz |
|---|---|
| **Curvatura em perspectiva** | mapeamento inverso tela → textura, resolvido por iteração de contagem fixa |
| **Blur progressivo** | espiral de ângulo áureo com 13 taps, raio zero na faixa plana e máximo na borda |
| **Sombreamento** | a borda que tomba recebe menos luz |
| **Tint de vidro** | mistura sutil com azul frio, na linguagem Liquid Glass |
| **Especular** | realce fino onde a curvatura começa, contido para não lavar a imagem |
| **Vignette** | fade para o void em direção ao topo e à base |

Com `uFold == 0` o shader faz *early return* pixel-perfect, e o Dart descarta o
`AnimatedSampler` por completo — com a tela plana não se paga snapshot por
frame nem se perde nitidez.

## Como a inclinação vira dobra

O ângulo sai de um **filtro complementar** sobre os dois sensores, porque nenhum
dos dois serve sozinho: o acelerômetro dá o ângulo absoluto contra a gravidade
mas treme a cada passo, e o giroscópio é suave mas deriva e não sabe onde é o
chão.

```
tilt_acel = atan2(√(ĝx² + ĝy²), ĝz)          0 rad deitado, π/2 na vertical

d(tilt)/dt = (ωx·ĝy − ωy·ĝx) / √(1 − ĝz²)    taxa exata, derivada de dĝ/dt = −ω × ĝ

tilt = 0,86·(tilt + taxa·dt) + 0,14·tilt_acel
```

A taxa do giroscópio é exata, não aproximada: como a gravidade é fixa no mundo,
no referencial do aparelho ela gira com `−ω`, e derivar `tilt = acos(ĝz)` dá a
fórmula acima. Perto de `ĝz = ±1` ela é singular — com o aparelho deitado não
existe eixo de tombamento definido — e ali o acelerômetro, que já é preciso
nesse ponto, assume sozinho.

O ângulo vira dobra com zona morta de 6° (uma mesa não é um plano perfeito) e
fechamento aos 70°, por uma curva `smoothstep` para a tela não estalar para fora
do plano.

## Sem sensor, e sem querer sensor

A inclinação nunca é a única rota:

- **Sem acelerômetro** — nenhuma amostra na janela de partida, e o seletor de
  inclinação some em vez de ficar apagado.
- **Movimento reduzido ligado no sistema** — a inclinação sai do caminho. Lido
  pelos dois canais, `MediaQuery.disableAnimationsOf` (Android) e
  `AccessibilityFeatures.reduceMotion` (iOS), porque ler só um derruba em
  silêncio os usuários da outra plataforma.
- **Sem suporte a shader** — o console diz isso e o mockup continua usável.

O controle manual está sempre lá, no rodapé, dentro do alcance do polegar: a
outra mão está segurando o aparelho inclinado.

## Rodar

```sh
flutter pub get
flutter run
```

O console fica no rodapé, fora da área que dobra — se dobrasse junto, o único
controle do app ficaria desfocado exatamente quando mais se precisa dele.

## Estrutura

```
shaders/duo_fold.frag      o efeito
lib/duo/
  tilt_sensor.dart         sensores e os estados que eles têm de verdade
  fold_controller.dart     estado único da dobra, do sensor ou do dedo
  duo_fold_config.dart     parâmetros do shader e a curva tilt → fold
  duo_shader.dart          carga e ciclo de vida do FragmentProgram
  duo_fold_view.dart       aplica o shader sobre a árvore de widgets
  fold_console.dart        estado do sensor e controle manual
lib/feed/                  o mockup do Halo
lib/theme/halo_theme.dart  tokens de cor, espaçamento, raio e toque
```

## Design

A UI segue a skill [Trunative](E:/Work/Personal/Trunative/skills/). Os briefs
que ela exige estão em `.trunative/`: `PRODUCT.md`, `DESIGN.md` (formato
design.md) e `STACK.md`, que também registra as exceções aceitas de propósito —
a trava em retrato é uma delas, porque a rotação automática competiria com a
inclinação e giraria a UI no meio da dobra.

## Escopo

Somente Android. Sem iOS, sem web, sem suíte de testes.

A verificação é `flutter analyze` mais o app rodando num aparelho — `flutter
build apk --debug` também compila o GLSL pelo `impellerc`, então um erro de
shader aparece no build e não só em tempo de execução.
