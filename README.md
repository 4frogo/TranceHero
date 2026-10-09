# TranceHero - prototipo jogavel Godot 4

Jogo estilo Guitar Hero de psytrance, 4 lanes, teclado D-F-J-K.
Baseado na referencia: highway neon em perspectiva, palco psy ao fundo.

## Como abrir
1. Abra o Godot 4.4.1 (`C:\Users\pedro\Tools\Godot_v4.4.1-stable_win64.exe`)
2. Importar -> selecione `C:\Users\pedro\Documents\TranceHero\project.godot`
3. Aperte F5 (Play). Cena principal: `scenes/Main.tscn`

## Como jogar
- D F J K = acertar as notas nos receptores
- L = ativa ESPECIAL quando 20/20
- ENTER / ESPACO = recomecar
- Perfect <60ms (300pts), Otimo <120ms (150pts), Bom <180ms (50pts)
- Combo 8=x2, 16=x4, 32=x8. Fever dobra tudo por 10s.

## Como colocar musica de verdade
1. Converta seu mp3 para .ogg (Godot prefere ogg. Use Audacity ou ffmpeg: `ffmpeg -i musica.mp3 -c:a libvorbis musica.ogg`)
2. Copie para `audio/musica1.ogg`
3. Em `scripts/Main.gd` funcao `_build_audio()`, a lista `paths` ja tenta carregar `audio/musica1.ogg` automaticamente.
4. Descubra o BPM (ex: 142) e ajuste `const BPM` no topo do `Main.gd`.
5. Edite o chart em `charts/test_chart.json`:
```json
{"bpm":142, "song":"minha-musica", "notes":[[2.0,0],[2.42,1],[2.85,2]]}
```
tempo em segundos, lane 0-3. Dica: tempo = beat * 60/BPM.

## Proximos passos sugeridos
- Trocar fundo procedural por sua imagem: salve em `art/bg.png` e me avise que eu ligo no codigo
- Receptores com seus simbolos (espiral, olho, sol, triskele) como PNG
- Menu + selecao de musicas + Hold notes (notas longas)
