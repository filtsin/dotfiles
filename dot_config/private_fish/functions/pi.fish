function _pi_bwrap
   set -l git_bind

   if test -d "$PWD/.git"
       set git_bind --bind "$PWD/.git" "$PWD/.git"
   end

   # jiti кэширует транспиляцию TS/ESM-расширений в $TMPDIR/jiti.
   # /tmp остаётся приватным RAM-tmpfs; на диск персистим только кэш jiti.
   mkdir -p "$HOME/.cache/pi-jiti"

   bwrap \
       --ro-bind /usr /usr \
       --ro-bind /bin /bin \
       --ro-bind /lib /lib \
       --ro-bind /lib64 /lib64 \
       --ro-bind /etc/resolv.conf /etc/resolv.conf \
       --ro-bind /etc/ssl /etc/ssl \
       --ro-bind /etc/ca-certificates /etc/ca-certificates \
       --ro-bind /etc/hosts /etc/hosts \
       --proc /proc \
       --dev /dev \
       --tmpfs /tmp \
       --bind "$HOME/.cache/pi-jiti" /tmp/jiti \
       --dir /home \
       --dir /var \
       --dir /var/run \
       --bind-try /var/run/docker.sock /var/run/docker.sock \
       --ro-bind "$HOME/.gitconfig" "$HOME/.gitconfig" \
       --bind "$HOME/.config/herdr" "$HOME/.config/herdr" \
       --bind "$HOME/.local/share/chezmoi" "$HOME/.local/share/chezmoi" \
       --bind "$HOME/.pi-lens" "$HOME/.pi-lens" \
       --bind "$HOME/.agents" "$HOME/.agents" \
       --bind "$HOME/.cargo" "$HOME/.cargo" \
       --bind "$HOME/.rustup" "$HOME/.rustup" \
       --ro-bind "$HOME/.local/share/nvim/mason" "$HOME/.local/share/nvim/mason" \
       --ro-bind "$HOME/.config" "$HOME/.config" \
       --bind "$HOME/.config/herdr-app" "$HOME/.config/herdr-app" \
       --bind "$HOME/.local/share/herdr-app" "$HOME/.local/share/herdr-app" \
       --bind "$HOME/go" "$HOME/go" \
       --bind "$HOME/.local/bin" "$HOME/.local/bin" \
       --bind-try "$HOME/.local/share/rtk" "$HOME/.local/share/rtk" \
       --bind-try "$HOME/.cache/codebase-memory-mcp" "$HOME/.cache/codebase-memory-mcp" \
       --ro-bind "$XDG_RUNTIME_DIR/$WAILAND_DISPLAY" "$XDG_RUNTIME_DIR/$WAILAND_DISPLAY" \
       --bind-try "$NIRI_SOCKET" "$NIRI_SOCKET" \
       --bind "$PWD" "$PWD" \
       $git_bind \
       --bind "$HOME/.pi" "$HOME/.pi" \
       --setenv PATH "$HOME/.cargo/bin/:$HOME/.local/bin/:$HOME/.local/share/nvim/mason/bin:/usr/bin:/bin" \
       $argv \
       -- pi $_PI_ARGS
end

function pi
   echo "running in bwrap"
   set -g _PI_ARGS $argv
   _pi_bwrap
end
