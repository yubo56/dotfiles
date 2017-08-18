# Yubo Dotfiles

These are all my dotfiles and now a lot more. Want to be able to pacstrap, clone the repo and make install *all* the things.

## Order of things
- Set up partitions (`fdisk` or through native OS)
- Mount `/mnt` and `/mnt/boot`
- `pacstrap -i /mnt base base-devel`
- `arch-chroot /mnt`
- `pacman -S git`
- `git clone https://yubo56@github.com/yubo56/dotFiles.git ~dotfiles`
    - use personal access token from Gmail Tasks
- `make root`
- Reboot, login to new user
- Re-encode keys, after new keybase user is added
- `make linux`

## misc notes
- Screensaver on suspend uses 00xscreensaver on home, xscreensaver.service on Mac
- `pm-suspend` still doesn't work on Mac
- `karabiner.json` belongs in `~/.config/karabiner/karabiner.json`

## fonts
- Under chrome: advanced font settings:
    - [Script]: [font size], [standard], [serif], [sans], [monospace]
    - Default: 20, Sans, Serif, Sans, Monospace
    - Hangul: 20, Baekmuk Batang, Baekmuk Batang, Baekmuk Batang, Default
    - Simplified Han: 20, UKai CN, UKai CN, UKai CN, Default

## Setup on Mac
- `yaourt -S hid-apple-patched-git`, use config file from `.setup/config_manual`

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
