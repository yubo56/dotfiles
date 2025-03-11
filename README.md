# Yubo Dotfiles

These are all my dotfiles and now a lot more. Want to be able to pacstrap,
clone the repo and make install all the things.

## Order of things
- UEFI + set up partitions (`fdisk` or through native OS)
    - Note: May need to write GPT + create EFI partition
    - `mkfs.ext4 /dev/sdaX`
- Mount `/mnt`
- `pacstrap -i /mnt base base-devel linux linux-firmware`
- Mount `/mnt/boot`
- `genfstab -U /mnt > /mnt/etc/fstab`
- `bootctl --esp-path=/mnt/boot install`, then create entries + `loader.conf`
    - Sample entry
```
title Arch Linux Macbook
linux /vmlinuz-linux-macbook
initrd /initramfs-linux-macbook-fallback.img
options rw root=UUID=<...>
```
- `/mnt/etc/locale.conf` edits, `echo KEYMAP=dvorak > /mnt/etc/vconsole.conf`
- `arch-chroot /mnt`
- `locale-gen`
    - NB: do not forget this step, need locales to xdg-open correctly
- `pacman -S git dhcpcd zsh gvim`
    - gvim since I'll want +X11 support later anyway, though it's much larger
- `git clone https://yubo56@github.com/yubo56/dotFiles.git ~/dotfiles`
    - can comment out `install_wpa_supplicant` if have lan connection
    - use personal access token from Gmail Tasks
    - *may need to grab keybase-encrypted id_rsa*
- `make root`

- Reboot, login to new user
- `sudo dhcpcd` or connect to wifi
- clean `/etc/pacman.d/mirrorlist`
- `make linux`

## Setup on Mac (MacOS)
- On mac, set hostname: `sudo scutil --set HostName <...>`
- `karabiner.json` belongs in `~/.config/karabiner/karabiner.json`
    - Simple mods (should be in k.json): ust remap capslock -> control in system
      prefs, swap left_option and left_command for every individual keyboard,
      swap Fn and left_ctrl for MacOS (should be in Karabiner.json)
    - Rules are applied in reverse precedence
    - Convention: map from only left modifiers, map only to right modifiers
- "System Preferences > Keyboard > Shortcuts > App Shortcuts", add bizzare
  modifier for 'Minimize/Minimise' to disable accidental minimize
    - Can also use Automator to start screen saver, add shortcut under Services
        - "Quick Action" --> "Start Screen Saver" (search) --> "Workflow
          receives: no input" --> <name>
        - Settings: Keyboard --> Shortcuts --> Services --> <name>

- Notes from latest setup (Aug 31, 2022):
    - install dev tools, keybase, karabiner
    - git clone dotfiles, get `id_rsa` to bootstrap all private repos
        - git submodule init, `make submodule_to_htps`, git submodule update
          private, `make decode_keys`, `make submodule_to_git`, then `git
          submodule update --recursive`
    - install brew
    - brew install stow, tmux, coreutils, moreutils
        - linearmouse for disable mouse accel
    - may need to cp `python3` and `pip3` in brew bin to un-namespaced
    - `brew install vim`
    - if Intel silicon, will need to change $PATH

- Secure Keyboard Entry seems to automatically get enabled in Terminal.app.
  Workaround is to use iTerm2, but open a Terminal in the background (which
  absorbs the SKE)

## Setup on Mac (linux)
- `yaourt -S hid-apple-patched-git-dkms`, use config file from `.setup/config_manual`
- To get IGD:
    - `apple_set_os`, add bootloader entry
    - kernel param `mem_encrypt=off`
    - may need to compile with kernel params
```
CONFIG_EXTRA_FIRMWARE="radeon/verde_ce.bin radeon/verde_mc.bin radeon/verde_me.bin radeon/verde_pfp.bin radeon/verde_rlc.bin radeon/verde_smc.bin radeon/TAHITI_uvd.bin"
CONFIG_EXTRA_FIRMWARE_DIR="/lib/firmware"
```

## misc notes
- Screensaver on suspend uses 00xscreensaver on home, xscreensaver.service on Mac
- `sudo sysctl kernel/unprivileged_userns_clone=1` for Brave namespaces
- Bluetooth headset: `bluez bluez-utils pulseaudio-bluetooth pulseaudio-alsa`
    - Pulseaudio asound.conf, `/etc/pulse/defaultpa`:
        `load-module module-switch-on-connect`
    - `bluetoothctl`:
        `power on; agent on; scan on; pair <...>; trust <...>; connect <...>`
- transparency: `sudo pacman -S xcompmgr transset-df`
    - `devilspie` used to be used to match windows on open, broken now
- droidcam `/etc/modprobe.d/droidcam.conf` resolution, `/opt/urserver/urserver`
  to start Unified Remote
    - `yaourt -S droidcam adb unified-remote-server`
- For audio, need `~/.asoundrc`, check which sound card via alsamixer, then
```
pcm.!default {
    type hw
    card 1
}
ctl.!default {
    type hw
    card 1
}
```
    - When bluetooth is connected, need to use pulseaudio, default is in
      `/etc/asound.conf`, e.g.
```
pcm.!default {
  type pulse
  fallback "sysdefault"
  hint {
    show on
    description "Default ALSA Output (currently PulseAudio Sound Server)"
  }
}

ctl.!default {
  type pulse
  fallback "sysdefault"
}
```
- if dmenu is randomly crashing, `strace dmenu_run`, but probably need to git
  clone and re-install (4.9-1 seems to have this problem)
- Anaconda install: `conda install -c lightsource2-tag zsh`,
    `conda install -c conda-forge gcc_linux-64`
- To get headphones + mic working:
    - can I figure out autobluetooth?
    - `pacmd set-card-profile <card> headset_head_unit` or `a2dp_sink` (latter
      is the high-quality audio, no source)
    - `pactl set-default-source <card>`

# Misc commands to save
- resizing image while removing virtual canvas
    - `convert in.png -crop nxn+0+0 +repage out.png`
- resizing PDF with ghostscript
```
    ~/Downloads$ gs \
     -o c.pdf \
     -sDEVICE=pdfwrite \
     -dDEVICEWIDTHPOINTS=720 -dDEVICEHEIGHTPOINTS=1280 \
     -dFIXEDMEDIA \
     -dPDFFitPage \
     -dCompatibilityLevel=1.4 \
      b.pdf
```
- combining pdf pages
    - `pdftk a.pdf b.pdf cat output c.pdf`
- ffmpeg image -> video
    - `ffmpeg -framerate 8 -pattern_type glob -i '*uz*.png' test.mp4`
    - `ffmpeg -ss 00:00:00 -t 0:02:00 -i in.mp4 -acodec copy -vcodec copy out.mp4`
- `exec screen -R -s /usr/bin/zsh` in `~/.bash_profile`
    - profile to avoid running on ssh, shell to specify alt shell
- `~/.ssh/authorized_keys`: put public key,
    - `chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys`
- `/^1?$|^(11+)\1+$/` matches non-prime numbers of 1s
- IBus errors:
    - `Config value [engine/hangul:on-keys] does not exist.` and for off-keys
        - `dconf write /desktop/ibus/engine/hangul/on-keys \'\'`
        - `dconf write /desktop/ibus/engine/hangul/off-keys \'\'`
    - IBus menus won't show, frozen
        - `git clone`, ensure have `gnome-common unicode-emoji
          cldr-emoji-annotation vala iso-codes` installed (10/27/20)
        - `./autogen.sh`
        - recompile w/ `ibusproperty.c:ibus_property_update()` line
          `set_visible` commented out (or the gassert priv_update->type?)
        - needed to change engine/Makefile to prefix = `/usr/share`, not
          `/usr/local/share`
- To split/join files, `split -b 200M a.tar.gz "a.tar.gz.part"`, can just cat
  them all together to join
- `/etc/security/faillock.conf` - `deny = 0` to stop blocking on failed login
- Invert colors: `convert in.png -negate out.png`
    - transparency: `convert in.png -transparent black out.png` (png, not jpg)
        - can use `-fuzz 5%` or so to get rid of spottiness
- `mplayer -font "AR PL UKai CN"` seems to work for chinese subs
    - `find . -type f | shuf | xargs mplayer -loop 0` to shuffle on repeat
      everything in dir
- `shuf -e $('ls')` to shuffle files in current directory
- Getting locked out: `/etc/security/faillock.conf`, and use `faillock` to reset
- Sorting Amex offers
    - `g!/^Spend/d | %s/^Spend \$\([^ ]\+\) .*get \$\([^ ]\+\) .*/\2\/\1/g | %s/,//g | %s/+//g | let @q=":read !bc -l <<< \<C-R>=getline('.')\<CR>\<CR>ddkPJj"`
- Firefox tweaks:
    - `about:config > toolkit.legacyUserProfileCustomizations.stylesheets > true`
    - copy to `<Firefox profile folder>/chrome/userChrome.css`
    - also, set something.uidensity = 1

- macos keyboard settings
```
    defaults write -g ApplePressAndHoldEnabled -bool false
    defaults write -g InitialKeyRepeat -int 10
    defaults write -g KeyRepeat -int 1
```
- ipython startup scripts: `~/.ipython/profile_default/startup`

- to bulk downgrade arch (double `u` allows downgrades)
```
    echo 'Server=https://archive.archlinux.org/repos/2018/04/05/$repo/os/$arch' > /etc/pacman.d/mirrorlist
    pacman -Syyuu
```
