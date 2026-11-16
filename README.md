# Starfield Screensaver

Proteção de tela de estrelas voando em direção à tela, no estilo do clássico
"Flying Through Space" do Windows 3.1/95, para o **xfce4-screensaver**
(testado no Xubuntu/Ubuntu 26.04 com XFCE, X11). Implementação própria em
Python, usando a libX11 via `ctypes`, sem dependências extras.

## Instalação

```sh
git clone <url-deste-repositorio>
cd starfield-screensaver
./install.sh
```

Teste com `xfce4-screensaver-command --activate`. Para ver numa janela comum:
`./starfield --window`.

## Ajustes

No começo do arquivo `starfield`: `NUM_STARS` (quantidade), `SPEED`
(velocidade) e `FPS`. Depois de editar, rode `./install.sh` de novo.

## Notas

- O `.desktop` precisa de pelo menos um argumento no `Exec` (aqui `--root`).
  Sem isso o xfce4-screensaver recebe um comando vazio e mostra tela preta.
- O xfce4-screensaver só lê temas de `/usr/share/applications/screensavers/`.
- Funciona apenas em X11 (não Wayland).

## Licença

MIT
