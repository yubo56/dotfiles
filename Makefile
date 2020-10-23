# Makefile with targets for instant system config!
# 		assumes is in ~/dotfiles directory
# 		all dependencies commented out so can perpetually use :)

PKGEXT=.pkg.tar # vim, dwm
WIFI_INTERFACE=wlp4s0# wifi
USERNAME=yssu

PQ_TMP_DIR=/tmp/pq
YAOURT_TMP_DIR=/tmp/yaourt
VIM_TMP_DIR=/tmp/vim
PWD=$$(pwd)
PACMAN=pacman --noconfirm
YAOURT=yaourt --noconfirm

.PHONY: linux
linux: \
	change_shell\
	submodules_to_https\
	update_plugins\
	mirrorlist\
	pacman\
	yaourt\
	install_keybase\
	decode_keys\
	re_encode_keys\
	stow\
	git_ssh\
	dwm\
	change_git_repo\
	submodules_to_ssh\
	lm_sensors\
	ntp\
	etc\
	ctags\
	enable_dhcpcd\
	undodir\
	wifi # connect_wifi

.PHONY: root
root: timezone create_user sudoers hostname #install_wpa_supplicant

##############################################################################
##############################################################################
#########################    SU SETUP SECTION     ############################
##############################################################################
##############################################################################

.PHONY: create_user
create_user:
	passwd
	grep '^${USERNAME}' /etc/passwd || useradd -m -s /bin/bash ${USERNAME}
	passwd ${USERNAME}
	cp -r . ~${USERNAME}/dotfiles
	chown -R yssu ~${USERNAME}/dotfiles
	chown -R yssu ~${USERNAME}/dotfiles/.git

.PHONY: sudoers
sudoers:
	chown root ~${USERNAME}/dotfiles/.setup/sudoers
	rm -f /etc/sudoers
	ln ~${USERNAME}/dotfiles/.setup/sudoers /etc/sudoers

.PHONY: hostname
hostname:
	@read -p "Hostname: " HOSTNAME && echo $$HOSTNAME > /etc/hostname

.PHONY:timezone
timezone:
	timedatectl set-local-rtc yes
	timedatectl set-ntp true
	timedatectl set-timezone America/New_York

.PHONY: install_wpa_supplicant
install_wpa_supplicant:
	pacman -Q wpa_supplicant || ${PACMAN} -S wpa_supplicant

##############################################################################
##############################################################################
#########################    LINUX SETUP SECTION     #########################
##############################################################################
##############################################################################


.PHONY: change_git_repo
change_git_repo:
	git remote set-url origin git@github.com:yubo56/dotfiles.git

.PHONY: mod_user
mod_user: # pacman (need sudo, zsh)
	sudo groupadd sudo
	su -c 'usermod -g sudo yssu -s /bin/zsh'

.PHONY: install_keybase
install_keybase:
	pacman -Q keybase-bin || ${YAOURT} -S keybase-bin
	run_keybase
	keybase login yssu

.PHONY: decode_keys
decode_keys: # install_keybase
	cd private && for i in $$(find . -iname *.kb); do\
		keybase decrypt -i $$i -o "$${i%.*}"; \
		chmod 600 "$${i%.*}"; done

.PHONY: etc
etc:
	cd .setup/etc && for i in $$('find' . -type f); do sudo rm -rf /etc/$$i &&\
		sudo ln -s ${PWD}/$$i /etc/$$i; done

# to install pacman packages
.PHONY: pacman
pacman:
	@printf '*** Installing pacman packages... ***\n'
	sudo ${PACMAN} -S --needed - < ~/dotfiles/.setup/pkglist.txt
	@printf '*** Installed pacman packages! ***\n\n'

.PHONY: package-query
package-query:
	rm -rf ${PQ_TMP_DIR}
	mkdir -p ${PQ_TMP_DIR}
	git clone https://aur.archlinux.org/package-query.git ${PQ_TMP_DIR}
	cd ${PQ_TMP_DIR} && makepkg -si --noconfirm
	rm -rf ${PQ_TMP_DIR}

.PHONY: yaourt
yaourt: package-query
	rm -rf ${PQ_TMP_DIR}
	mkdir -p ${YAOURT_TMP_DIR}
	git clone https://aur.archlinux.org/yaourt.git ${YAOURT_TMP_DIR}
	cd ${YAOURT_TMP_DIR} && makepkg -si --noconfirm
	rm -rf ${PQ_TMP_DIR}
	gpg --recv-keys 1C61A2656FB57B7E4DE0F4C1FC918B335044912E
	${YAOURT} -S downgrade goldendict brave-beta-bin zoom slack-desktop

# DEPRECATED infinality is dead :(
.PHONY: infinality
infinality: # pacman
	@echo Adding infinality server
	@echo -e '[infinality-bundle]\nServer = http://bohoomil.com/repo/$$arch'\
		| sudo tee -a /etc/pacman.conf
	@sudo pacman-key -r 962DDE58 && sudo pacman-key -f 962DDE58 &&\
		sudo pacman-key --lsign-key 962DDE58
	sudo pacman -Syy && sudo ${PACMAN} -S infinality-bundle

# set up vim with with-x=yes (deprecated if just install gvim instead)
.PHONY: vim
vim: # pacman
	@printf '*** Cloning vim... ***\n'
	@rm -rf ${VIM_TMP_DIR}
	@sudo rm -rf ${VIM_TMP_DIR}
	@cd /tmp && asp export extra/vim > /dev/null
	@printf '*** Building vim... ***\n'
	cd ${VIM_TMP_DIR} &&\
		sed -i 's/with-x=no/with-x=yes/g' PKGBUILD &&\
		PKGEXT=${PKGEXT} makepkg -s &&\
		sudo ${PACMAN} -U $$(makepkg --packagelist | grep '^vim.*x86_64' | sed 's/$$/${PKGEXT}/g') > /dev/null
	@rm -rf ${VIM_TMP_DIR}
	@printf '*** Vim installed! ***\n\n'
	mkdir -p ~/.undodir

# dwm window manager
# hard code cleanup to make sure nothing important gets cleaned up
.PHONY: dwm
dwm: # pacman
	@cd ~/dotfiles/.setup/custom/dwmalt &&\
		PKGEXT=${PKGEXT} makepkg -efi --noconfirm &&\
		rm -rf pkg $$(makepkg --packagelist | grep x86_64)${PKGEXT}
	@cd ~/dotfiles/.setup/custom/dwmalt/src/dwmalt-6.0 && make clean

.PHONY: pacupdate
PU_PATH=/etc/systemd/system
pacupdate: #pacman
	cd .setup/pu && for i in $$('ls'); do\
		sudo rm -f ${PU_PATH}/$$i &&\
		sudo ln -s ${PWD}/$$i ${PU_PATH}/$$i; done
	sudo systemctl enable ${PU_PATH}/pacupdate.service
	sudo systemctl enable ${PU_PATH}/pacupdate.timer

# stow files. Requires pacman to have stow installed
# Tries stow -R if normal stow fails
.PHONY: stow
stow: # pacman
	rm -rf ~/.gnupg # during install process, this folder is created, rm it w/e
	mkdir -p ~/.config
	@printf '*** Stowing Files... ***\n'
	stow `'ls' -d */` || stow -R `'ls' -d */`
	rm -f ~/.config/redshift.conf
	rm -rf ~/.config/zathura
	ln -sf ~/dotfiles/.setup/misc/redshift.conf ~/.config/redshift.conf
	ln -sf ~/dotfiles/.setup/misc/zathura ~/.config/zathura
	ln -sf ~/dotfiles/.setup/misc/chromium-flags.conf ~/.config/chromium-flags.conf
	@printf '*** Stowed Files! ***\n\n'

# mirrorlist sort
.PHONY: mirrorlist
mirrorlist: # pacman
	sudo ${PACMAN} -S pacman-contrib
	@sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.full
	@printf '*** Generating mirrorlist... ***\n'
	@sudo rankmirrors /etc/pacman.d/mirrorlist.full | sudo tee /etc/pacman.d/mirrorlist > /dev/null
	@printf '*** Done generating mirrorlist! ***\n\n'

# set up git to use ssh key + ssh clone URL
.PHONY: git_ssh
git_ssh: # pacman stow
	@printf '*** Setting up ssh... ***\n'
	@eval "`ssh-agent -s`" && ssh-add ~/.ssh/id_rsa
	@printf '*** Set up ssh! ***\n\n'

.PHONY: wifi
wifi: # pacman
	keybase decrypt -i .setup/wpa_supplicant.conf.kb -o .setup/wpa_supplicant.conf; \
	sudo chmod 600 .setup/wpa_supplicant.conf
	sudo rm -f /etc/wpa_supplicant/wpa_supplicant.conf
	sudo ln -s ${PWD}/.setup/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant.conf
	sudo systemctl enable wpa_supplicant.service
	cd /etc/wpa_supplicant && \
		sudo rm -f wpa_supplicant-${WIFI_INTERFACE}.conf && \
		sudo ln -s wpa_supplicant.conf wpa_supplicant-${WIFI_INTERFACE}.conf\
		2> /dev/null

.PHONY: connect_wifi
connect_wifi:
	sudo wpa_supplicant -i${WIFI_INTERFACE} -c/etc/wpa_supplicant/wpa_supplicant.conf\
		-B
	sudo dhcpcd ${WIFI_INTERFACE}

.PHONY: enable_dhcpcd
enable_dhcpcd:
	sudo systemctl enable dhcpcd.service

.PHONY: screensaver
screensaver: # pacman
	sudo rm -f /usr/lib/pm-utils/sleep.d/00xscreensaver
	sudo ln ${PWD}/.setup/misc/00xscreensaver \
		/usr/lib/pm-utils/sleep.d/00xscreensaver

.PHONY: fonts
fonts:
	sudo sed -i.bak 's/KaitiM\ GB/UKai CN/g' \
		/etc/fonts/conf.avail/65-nonlatin.conf
	sudo sed -i.bak 's/Baekmuk Dotum/Baekmuk Batang/g' \
		/etc/fonts/conf.avail/*

.PHONY: lm_sensors
lm_sensors: # pacman
	sudo sensors-detect

.PHONY: cabal
cabal: # pacman
	# reinstall all pacman packages since they're dynamically linked
	# few exceptions by regex handled at top of cabal.txt
	sudo ${PACMAN} -S ghc ghc-libs haskell-hslint
	cabal update
	cabal install --ghc-options=-dynamic --reinstall --force-reinstalls \
		$$(pacman -Q | 'grep' -o -e "haskell-[^ ]*" | sed 's/haskell-//g' |\
			sed 's/src-exts.*$$//g')\
		$$(cat .setup/cabal.txt)

##############################################################################
##############################################################################
##############################    MISC UTILS     #############################
##############################################################################
##############################################################################
change_shell:
	chsh -s $$(which zsh) $$(whoami)

update_plugins:
	git submodule update --init --recursive

submodules_to_https:
	sed -i.bak -E 's/git@(.*):/https:\/\/yubo56@\1\//g' .gitmodules
	rm .gitmodules.bak
	git submodule sync

submodules_to_ssh:
	sed -i.bak 's/https:\/\/.*github.com\//git@github.com:/g' .gitmodules
	rm .gitmodules.bak
	sed -i.bak 's/https:\/\/.*bitbucket.org\//git@bitbucket.org:/g' .gitmodules
	rm .gitmodules.bak
	git submodule sync

change_git_repo_https:
	git remote set-url origin https://yubo56@github.com/yubo56/dotfiles.git

.PHONY: re_encode_keys
re_encode_keys:
	cd private && for i in $$(find . -iname *.kb); do\
		chmod 644 "$${i%.*}" &&\
		keybase encrypt yssu -i "$${i%.*}" -o $$i &&\
		chmod 600 "$${i%.*}"; done

.PHONY: goldendict
goldendict:
	pacman -Q goldendict || ${YAOURT} -S goldendict
	rm -f ~/.goldendict/config
	ln -s ${PWD}/.setup/misc/gdict_config ~/.goldendict/config

PULL_CMD=((git checkout master && git pull) || true)
.PHONY: pull
pull:
	for i in $$(cat .gitmodules | grep path | sed -n -E 's/.*= (.*)$$/\1/p');\
		do (cd $$i && ${PULL_CMD}); done
	git reset && ${PULL_CMD}
	(cd vim && git submodule update --init)
	cd ~/HWSets && ${PULL_CMD} &&\
		cd ~/ClassNotes && ${PULL_CMD} &&\
		cd ~/research/nonlinear_breaking && ${PULL_CMD} &&\
		cd ~/su_self_study && ${PULL_CMD}

PUSH_CMD=((git add . && git commit -m "Push" && git push) || true)
.PHONY: push
push:
	for i in $$(cat .gitmodules | grep path | sed -n -E 's/.*= (.*)$$/\1/p');\
		do (cd $$i && ${PUSH_CMD}); done
	${PUSH_CMD}
	cd ~/HWSets && ${PUSH_CMD} &&\
		cd ~/ClassNotes && ${PUSH_CMD} &&\
		cd ~/research/nonlinear_breaking && ${PUSH_CMD} &&\
		cd ~/su_self_study && ${PUSH_CMD}

.PHONY: ntp
ntp: pacman
	sudo timedatectl set-ntp true

CTAGS_DIR=/tmp/ctags
.PHONY: ctags
ctags:
	rm -rf ${CTAGS_DIR}
	git clone https://github.com/majutsushi/ctags.git ${CTAGS_DIR}
	cd ${CTAGS_DIR} &&\
		ls &&\
		autoheader &&\
		autoconf &&\
		./configure &&\
		make &&\
		sudo make install

# make persistent undodir
.PHONY: undodir
undodir:
	mkdir ~/.undodir

SUSER_PATH=/home/${USERNAME}/dotfiles/.setup/systemd_user
systemd_user:
	mkdir -p ~/.config/systemd/user
	for i in $$('ls' ${SUSER_PATH}); do ln -s ${SUSER_PATH}/$$i ~/.config/systemd/user/$$i; systemctl --user enable $$i; done

##############################################################################
##############################################################################
##############################     STYLEBOT      #############################
##############################################################################
##############################################################################

TMPSTYLEFILE=stylebot_new.txt
REL_PATH=.setup/config_manual/stylebot

.PHONY: _stylebot
_stylebot:
	rm -f ${REL_PATH}/TMPSTYLEFILE
	vim ${REL_PATH}/TMPSTYLEFILE
	python3 ${REL_PATH}/parse_stylebot.py ${REL_PATH}/TMPSTYLEFILE\
		${REL_PATH}/TMPSTYLEFILE
	vimdiff ${REL_PATH}/TMPSTYLEFILE ${REL_PATH}/stylebot.bak
	rm ${REL_PATH}/TMPSTYLEFILE

.PHONY: stylebot_copy
stylebot_copy:
	(command -v xclip && xclip -selection c ${REL_PATH}/stylebot.bak)\
		|| pbcopy < ${REL_PATH}/stylebot.bak

.PHONY: stylebot
stylebot: _stylebot stylebot_copy

.PHONY: stylebot_copy_mac
stylebot_copy_mac:
	pbcopy < ${REL_PATH}/stylebot.bak
