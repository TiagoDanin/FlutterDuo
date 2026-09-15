---
name: Halo
version: 1.0.0
description: >
  Identidade de uma rede social de fotografia fictícia, desenhada para ser
  dobrada. O fundo é quase preto para que a dobra em GLSL tenha para onde
  escurecer, e o acento é o mesmo azul frio do tint de vidro do shader.
colors:
  light:
    surface: "#F7F8FA"
    surfaceContainer: "#FFFFFF"
    surfaceContainerHigh: "#EDEFF4"
    onSurface: "#11141B"
    onSurfaceVariant: "#555E6E"
    primary: "#2F4FD8"
    onPrimary: "#FFFFFF"
    outline: "#D7DBE3"
    error: "#B3261E"
  dark:
    surface: "#0B0D12"
    surfaceContainer: "#14171F"
    surfaceContainerHigh: "#1D212B"
    onSurface: "#EDF0F5"
    onSurfaceVariant: "#9AA3B2"
    primary: "#6E8BFF"
    onPrimary: "#06102B"
    outline: "#2A3040"
    error: "#FF6B6B"
typography:
  scale: material-3
  family: system
rounded:
  sm: 8
  md: 12
  lg: 16
  xl: 24
  full: 999
spacing:
  scale: [4, 8, 12, 16, 20, 24, 32]
components:
  - post-card
  - story-rail
  - fold-console
omitted:
  - elevation-tokens
  - brand-typeface
  - motion-tokens
---

# Halo

## Overview

Halo é o conteúdo, não o produto. Ele existe para que a curvatura em GLSL tenha
algo com hierarquia real para distorcer: texto pequeno ao lado de fotos
grandes, avatares redondos, uma barra fixa em cima e outra embaixo. Cada
decisão visual abaixo foi tomada perguntando o que acontece com ela quando o
shader a inclina, desfoca e escurece.

O efeito não parte a tela ao meio: o centro é o plano de foco, nítido e plano,
e são as bordas de cima e de baixo que tombam para trás. Isso decide o que
importa no layout — o que está no topo e no rodapé é o primeiro a sumir, e por
isso nada essencial mora lá dentro da área que curva.

## Colors

O modo escuro é o padrão e o modo que foi desenhado primeiro. O motivo é o
shader: ele escurece a borda que tomba até 45% e a funde num void quase preto
(`#050810`). Sobre uma superfície clara essa fusão vira uma mancha cinza; sobre
`#0B0D12` ela lê como profundidade.

O modo claro existe porque `color-dark-composed` não aceita uma aparência só, e
foi construído inteiro, não derivado por inversão. Nele o void do shader
continua escuro, o que é correto: a borda curvada revela a ausência de tela, e
ausência de tela não é branca.

Contraste medido sobre a superfície de cada tema:

| Papel | Escuro | Claro |
|---|---|---|
| `onSurface` | 15.8:1 | 15.4:1 |
| `onSurfaceVariant` | 7.4:1 | 6.1:1 |
| `primary` | 6.2:1 | 6.6:1 |

Todos acima de 4.5:1, com folga suficiente para sobreviver ao escurecimento que
o shader aplica no meio da dobra.

Um acento só, `primary`, e ele significa exatamente uma coisa: isto responde ao
toque. O coração curtido é a única exceção, e é `error` porque vermelho já é o
significado dele em toda rede social — inventar um segundo vermelho de marca
para curtida seria uma cor nova sem trabalho novo.

Nenhum gradiente decorativo. O único gradiente do app é o anel de story, e ele
tem um trabalho: distinguir um anel visto de um não visto sem depender de cor
sozinha (o não visto perde o anel inteiro, não só a saturação).

## Typography

A escala é a do Material 3, alcançada por papel (`titleLarge`, `bodyMedium`,
`labelSmall`) e nunca por tamanho literal. Cerca de quatro papéis por tela:
o nome de quem postou, a legenda, os metadados, e o rótulo dos controles.

Peso é estrutura: `w600` no nome e nas contagens, `w400` em todo o resto. Nada
de `w300` — o shader desfoca, e um traço fino desfocado desaparece antes de
ficar bonito.

O app precisa continuar legível no maior passo de acessibilidade. As linhas de
metadados podem quebrar; nenhuma altura de célula é fixa.

## Layout

Escala de espaçamento de 4 em 4, começando em 4 e terminando em 32. A gutter
horizontal do feed é 16.

Uma coluna, um eixo de rolagem. O trilho de stories é a única rolagem
horizontal e ela está dentro de um item que não rola verticalmente por conta
própria.

A safe area é lida em tempo de execução nas quatro bordas. Isso importa mais
aqui do que num app comum: o console de dobra fica no rodapé, dentro do
alcance do polegar, e é o único controle que o usuário realmente usa.

## Elevation & Depth

Sem sombras. A profundidade do app vem do shader, e uma sombra desenhada
compete com a sombra calculada — a metade que afunda fica com duas fontes de
luz discordando. As camadas se separam por superfície: `surface` no fundo,
`surfaceContainer` no card, `surfaceContainerHigh` no que está por cima dele.

## Shapes

Raio 16 nos cards, 12 nas fotos dentro deles, 8 nos chips, redondo total nos
avatares. Cantos redondos ajudam a leitura da curvatura: uma quina viva vira
serrilhado quando o shader a reprojeta em ângulo raso perto da borda.

## Components

- **post-card** — cabeçalho, foto, ações, legenda. A foto reserva a proporção
  antes de existir (`icon-reserve`), então a curvatura nunca acontece em cima
  de um layout que ainda está se mexendo.
- **story-rail** — avatares de 64, rolagem horizontal, anel gradiente para o
  não visto.
- **fold-console** — o estado do sensor e o controle manual de dobra. É chrome
  fixo no rodapé, dentro do alcance do polegar.

## Do's and Don'ts

- **Faça** o escuro primeiro e verifique o claro no aparelho, não no editor.
- **Faça** tudo alcançável com o polegar no terço inferior: o usuário está com
  a outra mão ocupada inclinando o aparelho.
- **Não** anime nada em laço dentro do feed. O shader já está redesenhando a
  tela inteira a cada frame; um shimmer em laço ao lado disso é orçamento de
  frame gasto duas vezes (`perf-overdraw`, `motion-loop`).
- **Não** use sombra, blur de widget ou vidro em widget. O único desfoque do
  app é o do shader; qualquer outro compete com ele e some na curvatura.
- **Não** use emoji como ícone. Um ícone é vetor e sobrevive à reprojeção; um
  emoji é uma imagem que fica borrada.
