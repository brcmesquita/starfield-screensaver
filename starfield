#!/usr/bin/env python3
"""Starfield: estrelas saindo do centro da tela e acelerando (estilo
"Flying Through Space" do Windows 3.1/95). Implementação própria.

Uso:
  starfield-screensaver            usa a janela em $XSCREENSAVER_WINDOW
  starfield-screensaver --root     idem (compatibilidade xscreensaver)
  starfield-screensaver --window   abre uma janela de teste
"""
import ctypes
import math
import os
import random
import sys
import time

NUM_STARS = 400
SPEED = 0.35          # fração de profundidade percorrida por segundo
FPS = 60

x11 = ctypes.CDLL("libX11.so.6")
c_ulong, c_int, c_uint, c_void_p = ctypes.c_ulong, ctypes.c_int, ctypes.c_uint, ctypes.c_void_p

x11.XOpenDisplay.restype = c_void_p
x11.XOpenDisplay.argtypes = [ctypes.c_char_p]
x11.XDefaultScreen.argtypes = [c_void_p]
x11.XRootWindow.restype = c_ulong
x11.XRootWindow.argtypes = [c_void_p, c_int]
x11.XCreateSimpleWindow.restype = c_ulong
x11.XCreateSimpleWindow.argtypes = [c_void_p, c_ulong, c_int, c_int, c_uint, c_uint, c_uint, c_ulong, c_ulong]
x11.XMapWindow.argtypes = [c_void_p, c_ulong]
x11.XGetGeometry.argtypes = [c_void_p, c_ulong] + [c_void_p] * 7
x11.XCreateGC.restype = c_void_p
x11.XCreateGC.argtypes = [c_void_p, c_ulong, c_ulong, c_void_p]
x11.XSetForeground.argtypes = [c_void_p, c_void_p, c_ulong]
x11.XFillRectangle.argtypes = [c_void_p, c_ulong, c_void_p, c_int, c_int, c_uint, c_uint]
x11.XCreatePixmap.restype = c_ulong
x11.XCreatePixmap.argtypes = [c_void_p, c_ulong, c_uint, c_uint, c_uint]
x11.XFreePixmap.argtypes = [c_void_p, c_ulong]
x11.XCopyArea.argtypes = [c_void_p, c_ulong, c_ulong, c_void_p, c_int, c_int, c_uint, c_uint, c_int, c_int]
x11.XFlush.argtypes = [c_void_p]
x11.XSync.argtypes = [c_void_p, c_int]


def geometry(dpy, win):
    root, x, y = c_ulong(), c_int(), c_int()
    w, h, bw, depth = c_uint(), c_uint(), c_uint(), c_uint()
    x11.XGetGeometry(dpy, win, ctypes.byref(root), ctypes.byref(x), ctypes.byref(y),
                     ctypes.byref(w), ctypes.byref(h), ctypes.byref(bw), ctypes.byref(depth))
    return w.value, h.value, depth.value


def new_star(far=False):
    # posição lateral aleatória e profundidade z em (0, 1]
    angle = random.uniform(0, 2 * math.pi)
    radius = random.uniform(0.02, 1.0)
    z = random.uniform(0.05, 1.0) if far else 1.0
    return [math.cos(angle) * radius, math.sin(angle) * radius, z]


def main():
    dpy = x11.XOpenDisplay(None)
    if not dpy:
        sys.exit("não foi possível abrir o display X11")

    if "--window" in sys.argv:
        screen = x11.XDefaultScreen(dpy)
        win = x11.XCreateSimpleWindow(dpy, x11.XRootWindow(dpy, screen), 0, 0, 800, 600, 0, 0, 0)
        x11.XMapWindow(dpy, win)
    else:
        env = os.environ.get("XSCREENSAVER_WINDOW")
        if not env:
            sys.exit("XSCREENSAVER_WINDOW não definido (use --window para testar)")
        win = int(env, 0)

    gc = x11.XCreateGC(dpy, win, 0, None)
    stars = [new_star(far=True) for _ in range(NUM_STARS)]
    w, h, depth = geometry(dpy, win)
    alpha = 0xFF000000 if depth == 32 else 0
    pix = x11.XCreatePixmap(dpy, win, w, h, depth)
    last = time.monotonic()
    frame = 0

    while True:
        now = time.monotonic()
        dt, last = now - last, now
        frame += 1
        if frame % 120 == 0:  # acompanha mudança de resolução
            nw, nh, _ = geometry(dpy, win)
            if (nw, nh) != (w, h) and nw and nh:
                x11.XFreePixmap(dpy, pix)
                w, h = nw, nh
                pix = x11.XCreatePixmap(dpy, win, w, h, depth)

        x11.XSetForeground(dpy, gc, alpha)
        x11.XFillRectangle(dpy, pix, gc, 0, 0, w, h)

        cx, cy = w / 2, h / 2
        scale = max(w, h) / 2
        for s in stars:
            s[2] -= SPEED * dt * (1.3 - s[2] * 0.6)  # acelera ao chegar perto
            if s[2] <= 0.01:
                s[:] = new_star()
                continue
            sx = int(cx + s[0] / s[2] * scale * 0.5)
            sy = int(cy + s[1] / s[2] * scale * 0.5)
            if not (0 <= sx < w and 0 <= sy < h):
                s[:] = new_star()
                continue
            v = int(255 * (1 - s[2]) ** 0.7)
            v = max(40, min(255, v))
            size = 1 if s[2] > 0.6 else 2 if s[2] > 0.25 else 3
            x11.XSetForeground(dpy, gc, alpha | (v << 16) | (v << 8) | v)
            x11.XFillRectangle(dpy, pix, gc, sx, sy, size, size)

        x11.XCopyArea(dpy, pix, win, gc, 0, 0, w, h, 0, 0)
        x11.XFlush(dpy)
        time.sleep(max(0, 1 / FPS - (time.monotonic() - now)))


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        pass
