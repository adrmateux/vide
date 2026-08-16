# Building vim 9.2 from the scratch

```shell
cd src
./configure \
    --with-features=huge \
    --enable-fail-if-missing \
    --enable-gui=gtk3 \
    --with-x \
    --enable-xim \
    --enable-multibyte \
    --enable-cscope \
    --enable-terminal \
    --enable-gpm=yes \
    --enable-luainterp=yes \
    --enable-perlinterp=yes \
    --enable-python3interp=yes \
    --enable-rubyinterp=yes \
    --enable-tclinterp=yes
make
sudo make install
```

Installation will be done at `/usr/local/bin`.

Automatic, no flag required — these just fall out of the combination above, confirmed in feature.h:
- balloon_eval — enabled automatically with GUI (FEAT_BEVAL_GUI) once huge+GTK are on
- clipboard / xterm_clipboard — auto-enabled once --with-x finds X11
- dnd — auto-enabled since it requires FEAT_CLIPBOARD + GTK GUI, both present
- toolbar, browse — auto-enabled with the GTK GUI
- netbeans — on by default (only need --disable-netbeans to turn it off, so nothing to pass)
- gettext — on by default (only --disable-nls turns it off)
- sodium — on by default if libsodium is found (only --disable-libsodium turns it off)
- sound — on by default if libcanberra is found (only --disable-canberra turns it off)
- hangul_input — this is XIM-based input, covered by --enable-xim above

--enable-fail-if-missing is worth keeping in since you want all of these guaranteed — without it, configure silently drops a feature if a dependency is missing instead of erroring.

Dependencies (Debian/Ubuntu — adjust if you're on another distro):
sudo apt install libgtk-3-dev libx11-dev libxpm-dev libxt-dev \
    libgpm-dev liblua5.4-dev lua5.4 \
    python3-dev libperl-dev ruby-dev tcl-dev \
    libsodium-dev libcanberra-dev libncurses-dev gettext

