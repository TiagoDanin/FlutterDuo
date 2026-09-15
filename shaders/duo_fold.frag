#version 460 core
#include <flutter/runtime_effect.glsl>

// ============================================================================
// duo_fold.frag — um lado do painel dobrando para trás, visto de frente.
//
// O modelo:
//
//   · A UI é um painel retangular. Uma das arestas VERTICAIS é a dobradiça e
//     ela NÃO se mexe: fica onde estava, encostada no plano. Só o outro lado
//     gira, afastando-se do observador.
//   · Um lado dobra de cada vez, nunca os dois. Qual deles é o sinal da
//     rotação que decide: gira-se para um lado e dobra o direito, para o outro
//     e dobra o esquerdo.
//   · O observador está parado, na normal do plano, alinhado com o centro, a
//     uEyeDistancePx de distância.
//   · Projetado nessa câmera, o painel deixa de ser um retângulo: vira um
//     quadrilátero, mais estreito e mais curto do lado que se afastou. O que
//     fica fora dele não é conteúdo — é fundo, e fundo é preto.
//   · O lado que se afasta perde nitidez e luz — é a distância que borra, e
//     borrar custa brilho. Junto à dobradiça o conteúdo continua nítido.
//
// O shader trabalha ao contrário, como todo fragment shader: para o pixel de
// tela, resolve que ponto do painel foi projetado ali. Se nenhum foi, é fundo.
// A relação inverte em forma fechada, sem busca iterativa — ver `panelAlong`.
// ============================================================================

uniform vec2  uSize;          // 0,1: tamanho do canvas em pixels lógicos
uniform float uTiltDegrees;   // 2: rotação com sinal, em graus
uniform float uEyeDistancePx; // 3: distância do observador ao plano, em px
uniform float uBlurSpread;    // 4: raio de borrão ganho por px de afastamento
uniform float uDarkening;     // 5: fração de luz perdida por px de raio
uniform float uCornerRadius;  // 6: raio dos cantos do painel, em px
uniform float uRimLight;      // 7: brilho do vidro na aresta, 0..1
uniform float uSpreadWidth;   // 8: alcance da dispersão para fora, em px
uniform float uSpreadStrength;// 9: o quanto da luz sobrevive fora, 0..1
uniform sampler2D uTexture;   // snapshot da UI renderizada

out vec4 fragColor;

const float kEps         = 1e-4;
const float kMaxTiltDeg  = 80.0;
// Contagem literal é exigência do Flutter, e 48 é o ponto onde o granulado
// para de aparecer nas áreas mais borradas. O jeito barato de borrar muito é
// uma pirâmide de mipmaps gaussianos, escolhendo o nível por log2(sigma) — mas
// isso pede passadas de pré-processamento que o `AnimatedSampler` não oferece,
// já que ele entrega uma textura só, sem mips. Aqui se paga em amostras.
const int   kMaxTaps     = 48;
const float kGoldenAngle = 2.39996322972865;
const float kTau         = 6.28318530717959;
const float kEdgeFeather = 1.0;  // px de suavização na borda do quadrilátero

// Em que fração do giro o arredondamento chega ao máximo. Na metade: o canto
// termina de abrir cedo e depois fica parado, em vez de mudar de forma durante
// todo o movimento.
const float kRoundSaturation = 0.5;

// Folga, em px de painel, que a dispersão precisa além da borda. Serve de
// early-out: passou disso, é fundo e não há o que espalhar. Tem que ser maior
// que `uSpreadWidth`, senão a dispersão é cortada antes de terminar.
const float kSpreadGuard = 420.0;

// Teto do borrão da dispersão, em px. Sem ele, um alcance grande pede um disco
// gigante e 48 amostras não dão conta: volta o granulado.
const float kSpreadBlurCap = 55.0;

// ----------------------------------------------------------------------------
// Amostra a UI num ponto dado em pixels.
//
// O sampler do Flutter trabalha em [0,1], então converte; e clampa porque as
// amostras do disco escapam do retângulo perto das bordas. O recorte do
// quadrilátero é feito depois, pela máscara, então o que o clamp inventa aqui
// acaba fora dela de qualquer forma.
// ----------------------------------------------------------------------------
vec3 samplePanel(vec2 pixel) {
    return texture(uTexture, clamp(pixel / uSize, 0.0, 1.0)).rgb;
}

// ----------------------------------------------------------------------------
// Um valor pseudoaleatório por pixel, para girar o disco de amostragem.
//
// Não precisa ser aleatoriedade boa. Precisa só não se alinhar com a grade de
// pixels: um disco de poucas amostras sempre desenha anéis, e girar cada pixel
// por um valor diferente troca os anéis por grão — que por sorte é exatamente
// a aparência que vidro fosco tem.
// ----------------------------------------------------------------------------
float pixelJitter(vec2 pixel) {
    vec3 p = fract(pixel.xyx * vec3(0.1031, 0.1030, 0.0973));
    p += dot(p, p.yzx + 33.33);
    return fract((p.x + p.y) * p.z);
}

// ----------------------------------------------------------------------------
// Distância assinada até a borda de um retângulo de cantos arredondados.
// Negativa dentro, zero na borda, positiva fora.
//
// É medida no espaço do PAINEL, antes da projeção, e é isso que faz os cantos
// se deformarem junto com o resto em vez de continuarem circulares na tela:
// um canto arredondado visto em ângulo é uma elipse, e sai de graça daqui.
// ----------------------------------------------------------------------------
float roundedRectDistance(vec2 fromCenter, vec2 halfSize, float radius) {
    float r = clamp(radius, 0.0, min(halfSize.x, halfSize.y));
    vec2 q = abs(fromCenter) - halfSize + r;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

// ----------------------------------------------------------------------------
// O brilho de vidro na aresta.
//
// A borda de um painel de vidro não termina: ela acende. A luz que entra rasa
// pela lateral corre pela espessura e sai concentrada numa linha fina bem no
// limite — é o que dá a leitura de vidro em vez de recorte.
//
// A faixa é estreita e some rápido para dentro, e some junto com a máscara
// para não vazar pelo lado de fora do recorte.
// ----------------------------------------------------------------------------
vec3 applyRim(vec3 color, float distance, float feather) {
    if (uRimLight <= 0.0) return color;

    // Um PICO na aresta, caindo para os dois lados.
    //
    // Antes isto era um `smoothstep` que subia até a borda e ficava em 1 dali
    // para fora — ou seja, somava brilho máximo em toda a área externa e
    // transformava a dispersão num halo de neon. A luz de aresta é uma linha
    // sobre a aresta; ela tem que morrer dos dois lados dela.
    float width = max(uCornerRadius * 0.12, feather * 2.0);
    float rim = 1.0 - clamp(abs(distance) / width, 0.0, 1.0);

    // Potência alta deixa a linha fina em vez de um degradê largo.
    rim = pow(rim, 3.0) * uRimLight;

    return clamp(color + vec3(rim), 0.0, 1.0);
}

// ----------------------------------------------------------------------------
// A inversão da projeção, ao longo da largura.
//
// A dobradiça é uma aresta vertical do painel, e ela NÃO se mexe: fica onde
// estava, encostada no plano. Só o outro lado gira, afastando-se. Por isso um
// lado dobra de cada vez — nunca os dois.
//
// Um ponto a `a` pixels da dobradiça, depois de girado por `tilt`, está em
//     x3d = hingeX + side*a*cos(tilt)
//     z3d = -a*sin(tilt)                  (negativo: afastando do observador)
// e a câmera o projeta com fator  s = D / (D + a*sin(tilt)).
//
// Igualando ao x de tela que estamos pintando e isolando `a`, ele sai sozinho
// — é linear depois de multiplicar pelo denominador:
//
//     a = D*(k - Sx) / (Sx*sin(tilt) - D*side*cos(tilt))
//
// onde Sx é o x de tela medido a partir do olho e k é a dobradiça medida do
// mesmo jeito.
// ----------------------------------------------------------------------------
float panelAlong(float screenX, float hingeX, float side, float tilt) {
    float eyeX = uSize.x * 0.5;
    float sx = screenX - eyeX;
    float k  = hingeX - eyeX;

    float denominator = sx * sin(tilt) - uEyeDistancePx * side * cos(tilt);
    if (abs(denominator) < kEps) {
        return -1.0; // degenerado: trata como fundo
    }
    return uEyeDistancePx * (k - sx) / denominator;
}

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;

    if (uSize.x <= 1.0 || uSize.y <= 1.0) {
        fragColor = texture(uTexture, fragCoord / max(uSize, vec2(1.0)));
        return;
    }

    float tilt = radians(clamp(abs(uTiltDegrees), 0.0, kMaxTiltDeg));

    // Painel de frente: ele preenche a tela exatamente, e não há nada a
    // projetar. Bypass exato, sem uma amostra sequer a mais.
    if (tilt < kEps) {
        fragColor = texture(uTexture, fragCoord / uSize);
        return;
    }

    // Qual aresta fica parada sai do SINAL da rotação, não de um uniform à
    // parte: um dado derivado viajando ao lado da sua fonte é a chance de os
    // dois discordarem, e aí o painel dobra para um lado com a dobradiça do
    // outro. Gira-se para um lado e dobra o direito, para o outro e dobra o
    // esquerdo — um de cada vez, nunca os dois.
    float hingeOnRight  = step(0.0, uTiltDegrees);
    float hingeX        = mix(0.0, uSize.x, hingeOnRight);
    float awayFromHinge = mix(1.0, -1.0, hingeOnRight);

    // Onde, ao longo da largura do painel, está o ponto que caiu neste pixel.
    float along = panelAlong(fragCoord.x, hingeX, awayFromHinge, tilt);

    // Longe demais da largura do painel: fundo, sem nem calcular o resto. A
    // folga é a da dispersão, que ainda precisa de conteúdo para espalhar.
    if (along < -kSpreadGuard || along > uSize.x + kSpreadGuard) {
        fragColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    // O afastamento daquele ponto, e o encolhimento que a câmera lhe aplica.
    float away   = max(along, 0.0) * sin(tilt);
    float shrink = uEyeDistancePx / max(uEyeDistancePx + away, kEps);

    // Desfazendo o encolhimento na vertical chegamos à altura no painel. Ele
    // encolhe em torno do olho, então é dali que a conta parte.
    float eyeY   = uSize.y * 0.5;
    float panelY = eyeY + (fragCoord.y - eyeY) / max(shrink, kEps);

    // Longe demais da altura do painel: fundo.
    if (panelY < -kSpreadGuard || panelY > uSize.y + kSpreadGuard) {
        fragColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    // Onde buscar a cor: `along` é medido a partir da dobradiça, então voltar
    // para a coordenada da imagem é andar essa distância a partir dela.
    vec2 source = vec2(hingeX + awayFromHinge * along, panelY);

    // --- O recorte, com os cantos arredondados ------------------------------
    // Uma tela tem canto arredondado; quina viva lê como folha de papel. O
    // recorte é feito no espaço do painel, então os cantos se deformam junto
    // com o resto: vistos em ângulo eles viram elipses, sem nenhum trabalho a
    // mais.
    //
    // A suavização é dividida pelo encolhimento porque, do lado que se afastou,
    // um pixel de tela cobre mais painel — e sem isso a borda distante ficaria
    // mais dura que a próxima.
    float feather = kEdgeFeather / max(shrink, kEps);

    // O canto CRESCE DE ZERO conforme o painel vira, e satura na metade do
    // giro.
    //
    // Partir de zero é o que torna a entrada contínua: de frente, o painel
    // ocupa a tela inteira e o canto que se vê é o da própria tela do aparelho
    // — desenhar um recorte arredondado ali seria somar um canto por cima de
    // outro, e ele apareceria inteiro de uma vez no instante em que o ângulo
    // saísse do zero. É esse degrau que lê como "de reto para redondo num
    // centímetro de movimento".
    //
    // A saturação na metade do giro vem do outro lado do mesmo problema: se o
    // crescimento se espalha por todo o percurso, o canto fica mudando de forma
    // o tempo inteiro enquanto o aparelho se mexe.
    float roundProgress = clamp(
        abs(uTiltDegrees) / (kMaxTiltDeg * kRoundSaturation),
        0.0,
        1.0
    );

    // Smoothstep duas vezes: a primeira tira as quinas da derivada nas duas
    // pontas, a segunda achata mais ainda o começo. O canto precisa demorar a
    // sair do nada, senão a chegada dele é o que se nota em vez do giro.
    roundProgress = roundProgress * roundProgress * (3.0 - 2.0 * roundProgress);
    roundProgress = roundProgress * roundProgress * (3.0 - 2.0 * roundProgress);

    float cornerRadius = uCornerRadius * roundProgress;

    float distance = roundedRectDistance(
        source - uSize * 0.5,
        uSize * 0.5,
        cornerRadius
    );

    // --- Dentro, borda, e a dispersão para fora -----------------------------
    // `outside` vai de 0 (dentro) a 1 (fora), suave na borda.
    float outside = smoothstep(-feather, feather, distance);

    // A dispersão: vidro não termina seco no preto. A luz que chega à aresta
    // sai espalhada para além dela e morre rápido. `fade` vale 1 exatamente na
    // borda — é isso que evita um degrau entre o conteúdo e o halo — e cai com
    // potência alta, porque dispersão é um rastro curto, não um brilho grande.
    float fade = 1.0 - clamp(distance / max(uSpreadWidth, kEps), 0.0, 1.0);

    // Potência baixa deixa o rastro LONGO. Com expoente alto ele morria em
    // poucos pixels e o que sobrava era um contorno, não uma dispersão — o
    // fundo voltava a ser preto quase encostado na aresta.
    fade = pow(max(fade, 0.0), 1.7);

    if (outside >= 1.0 && fade <= 0.0) {
        fragColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    // --- Nítido na dobradiça, dissolvendo conforme se afasta ----------------
    float radius = uBlurSpread * away;
    float attenuation = max(1.0 - uDarkening * radius, 0.0);

    // Fora da aresta o borrão abre bem mais: o que se vê ali não é o conteúdo,
    // é luz dele espalhada. Uma única amostragem serve aos dois casos.
    float sampleRadius = max(
        radius,
        outside * min(uSpreadWidth * 0.75, kSpreadBlurCap)
    );

    // Amostrar a partir de um ponto encostado na borda, e não de onde o pixel
    // caiu: fora do painel não existe conteúdo, e é a cor da aresta que deve
    // vazar.
    vec2 tap = clamp(source, vec2(0.5), uSize - vec2(0.5));

    // O quanto desta cor sobrevive: tudo dentro, o rastro da dispersão fora.
    float energy = attenuation * mix(1.0, fade * uSpreadStrength, outside);

    vec3 color;
    if (sampleRadius < 0.5) {
        // `flat` é palavra reservada no GLSL, como `half` — daí o nome.
        color = samplePanel(tap);
    } else {
        // --- Disco de amostragem --------------------------------------------
        // Espiral de ângulo áureo: as amostras se distribuem sem se empilhar, e
        // o raio por sqrt mantém a densidade uniforme por área em vez de
        // concentrar tudo no centro.
        //
        // A contagem precisa acompanhar o raio — 48 amostras num borrão de dois
        // pixels é desperdício —, mas o Flutter exige limite literal no loop. A
        // saída é rodar sempre 48 e zerar o peso das excedentes. O peso é
        // fracionário na fronteira em vez de ligar e desligar de uma vez, senão
        // o borrão dá um salto visível toda vez que a contagem sobe um degrau.
        float wantedTaps = clamp(sampleRadius * 2.4, 8.0, float(kMaxTaps));
        float spin = pixelJitter(fragCoord) * kTau;

        vec3  accumulated = vec3(0.0);
        float weightSum = 0.0;

        for (int i = 0; i < kMaxTaps; i++) {
            float index  = float(i);
            float weight = clamp(wantedTaps - index, 0.0, 1.0);
            float r      = sampleRadius * sqrt((index + 0.5) / wantedTaps);
            float angle  = index * kGoldenAngle + spin;

            accumulated += samplePanel(tap + r * vec2(cos(angle), sin(angle)))
                         * weight;
            weightSum += weight;
        }

        color = accumulated / max(weightSum, kEps);
    }

    fragColor = vec4(applyRim(color * energy, distance, feather), 1.0);
}
