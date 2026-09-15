# Halo — produto

## O que é

Demo técnica de um efeito visual: reproduzir em Flutter o *iPhone Duo effect*, a
transição do foldable da Apple, dirigida pela inclinação física do aparelho em
vez de por uma dobradiça real.

O efeito não parte a tela ao meio. O centro fica plano e nítido, e são as bordas
de cima e de baixo que tombam para trás, borrando e se dissolvendo no void.

O conteúdo curvado é **Halo**, um mockup de rede social de fotografia que não
existe. O mockup existe para dar ao shader algo com hierarquia real para
distorcer — texto pequeno, avatares redondos, fotos grandes, chrome fixo. Um
retângulo colorido não revelaria nada sobre o efeito.

## Quem usa, e em que situação

Desenvolvedores e designers avaliando o efeito. A sessão é curta, de pé, com o
aparelho na mão, inclinando-o para frente e para trás. Nunca é uma sessão de
trabalho: ninguém vai ler o feed, vão olhar as bordas.

## Os dois trabalhos que o app faz

1. Mapear a inclinação física do aparelho para o progresso da curvatura, de
   forma contínua e sem tremor.
2. Renderizar a curvatura em GPU sobre a UI real, sem congelá-la.

## Como é uma sessão

Segundos a poucos minutos. Duas mãos (uma segura, a outra às vezes ajusta o
controle manual). Sempre em primeiro plano — o efeito não tem sentido com o app
em segundo plano. Sem rede depois do primeiro carregamento das fotos.

## Restrições já decididas

- Flutter, um binário para Android, iOS e web.
- Deitado na mesa (tela para cima) é o estado **plano**. Inclinar fecha a dobra.
- O efeito é escrito em GLSL, não em widgets.
- As fotos vêm do Unsplash por URL. Nenhum backend, nenhuma conta, nenhum login.
- Nada é enviado para lugar nenhum: o app só faz GET de imagem.

## O que este app não é

Não é cliente de rede social. Não há publicar, comentar, seguir, mensagem ou
perfil editável. Os botões do mockup respondem ao toque (`touch-feedback`) e não
navegam para lugar nenhum, porque não existe lugar nenhum.
