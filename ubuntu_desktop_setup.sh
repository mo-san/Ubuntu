#!/usr/bin/env bash

function isCommand() {
	command -v "$1" &> /dev/null
}

function sayOK() {
	echo -e " ==> done"
}

echo -e "Setup starts."

if [ ! -f /etc/sudoers.d/default_options ]; then
	echo -e "\n--> this user will be able to do anything without password, and PATH will be inherited when you do sudo"
	cat <<- EOS | sudo tee /etc/sudoers.d/default_options > /dev/null
		Defaults env_keep += "PATH"
		Defaults !lecture
		Defaults !secure_path
		Defaults !authenticate
		Defaults !requiretty
		EOS
sayOK
fi

echo -e "\n--> setting up keyboard"
	today=$(date '+%Y-%m-%d')
	sudo sed -i_"$today".bak -re 's|XKBOPTIONS=""|XKBOPTIONS="ctrl:nocaps"|' /etc/default/keyboard
	sudo sed -i_"$today".bak -re 's|kernel.sysrq = 176|kernel.sysrq = 1|' /etc/sysctl.d/10-magic-sysrq.conf
sayOK

echo -e "\n--> setting root password for you to be root by 'su -'"
	echo "root:@[@[@[@[" | sudo chpasswd
sayOK

if [ ! -f ~/.hushlogin ]; then
	echo -e "\n--> stopping daily welcome message"
	touch ~/.hushlogin
sayOK
fi

if [ ! -f ~/.inputrc ]; then
	echo -e "\n--> stopping beep sound"
	echo -e "# stop beep sound\nset bell-style none" | tee -a ~/.inputrc >/dev/null
sayOK
fi

# 日本国内リポジトリが指定されていない、もしくはインストール後のデフォルトのままなら
apt_source="http://jp.archive.ubuntu.com/ubuntu/"
if (! grep -q $apt_source /etc/apt/sources.list) || (grep -q "# deb-src" /etc/apt/sources.list); then
	echo -e "\n--> switching to japanese APT repositories"
	cp /etc/apt/sources.list ~/apt_sources.list."$(date +%Y%m%d-%H%M)".orig
	cat > ~/sources.list <<- EOF
		deb $apt_source focal           main restricted universe multiverse
		deb $apt_source focal-updates   main restricted universe multiverse
		deb $apt_source focal-backports main restricted universe multiverse
		deb $apt_source focal-security  main restricted universe multiverse
		EOF
	sudo mv --force ~/sources.list /etc/apt/sources.list
sayOK
fi

echo -e "\n--> updating apt repositories"
	sudo apt-get update -qq
sayOK

# 進捗状況が見えるように、 -qq をつけない
echo -e "\n--> installing Japanese environment"
	sudo apt-get install -y \
	language-pack-ja \
	manpages-ja \
	manpages-ja-dev
sayOK

echo -e "\n--> installing some packages"
	sudo apt-get install -y \
	cifs-utils \
	curl \
	dnsutils \
	fd-find \
	git \
	highlight \
	jq \
	locate \
	ncdu \
	source-highlight \
	tree \
	unar \
	unzip \
	xsel \
	zsh \
	zsh-syntax-highlighting
sayOK

if ! isCommand pip; then
	echo -e "\n--> [installing] pip"
	wget http://bootstrap.pypa.io/get-pip.py -O ~/get-pip.py
	sudo python3 ~/get-pip.py
	rm ~/get-pip.py
sayOK
fi

echo -e "\n--> [installing] app on pip"
	sudo pip install --upgrade pip
	sudo pip install --quiet \
	ranger-fm \
	trash-cli \
	yq
sayOK

if ! grep -P "^$USER:" /etc/passwd | cut -d: -f7 | grep -q zsh; then
	echo -e "\n--> chainging login shell."
	chsh -s "$(which zsh)"
sayOK
fi

if [ ! -d ~/.nanobackup ]; then
	echo -e "\n--> [installing] nano syntax highlighting"
	# scopatz/nanorc: Improved Nano Syntax Highlighting Files
	# https://github.com/scopatz/nanorc
	mkdir -p ~/.nanobackup
	curl https://raw.githubusercontent.com/scopatz/nanorc/master/install.sh | sh
	sudo mv /etc/nanorc ~/nanorc.orig
	sudo ln -v ~/.nanorc /etc/nanorc
sayOK
fi

if ! [ -d ~/bin ]; then
	echo -e "Create directory for utils"
	mkdir -p ~/bin
sayOK
fi

if ! isCommand micro; then
	echo -e "\n--> [installing] micro"
	# curl https://getmic.ro | bash
	binary_url=$(wget -O - -q https://api.github.com/repos/zyedidia/micro/releases/latest | jq --raw-output '.assets[] | select(.browser_download_url | endswith("amd64.deb") ) | .browser_download_url')
	wget -q -O /home/"$USER"/micro.deb "$binary_url"
	sudo dpkg -i /home/"$USER"/micro.deb
	rm /home/"$USER"/micro.deb
sayOK
fi

if ! isCommand bat; then
	echo -e "\n--> [installing] bat (colored cat)"
	# https://github.com/sharkdp/bat
	binary_url=$(wget -O - -q https://api.github.com/repos/sharkdp/bat/releases/latest | jq --raw-output '.assets[].browser_download_url' | grep -P "musl.+amd64.deb$")
	wget -q -O /home/"$USER"/bat.deb "$binary_url"
	sudo dpkg -i /home/"$USER"/bat.deb
	rm /home/"$USER"/bat.deb
sayOK
fi

if ! isCommand fzf; then
	echo -e "\n--> [installing] fzf"
	# https://github.com/junegunn/fzf
	git clone --depth 1 --quiet https://github.com/junegunn/fzf.git ~/bin/fzf
	~/bin/fzf/install --all
sayOK
fi

echo -e "\n--> chmod ssh files"
	chmod 700 ~/.ssh/*
sayOK



echo -e "\n--> Install CLI apps"
	sudo apt install -y \
	htop \
	xbindkeys \
	xclip
sayOK
	# numlockx \

echo -e "\n--> Install GUI apps"
	sudo apt install -y \
	autokey-gtk \
	clipit \
	conky-all \
	easystroke \
	grub-customizer \
	guake \
	simplescreenrecorder \
	vlc
sayOK

if isCommand thunderbird; then
	echo -e "\n--> Remove Thunderbird"
	sudo apt remove --purge "thunderbird*"
sayOK
fi

if ! isCommand anydesk; then
	echo -e "\n--> Install AnyDesk"
	wget -qO - https://keys.anydesk.com/repos/DEB-GPG-KEY | sudo apt-key add -
	echo -e "deb http://deb.anydesk.com/ all main" | sudo tee /etc/apt/sources.list.d/anydesk-stable.list >/dev/null
	sudo apt-get -qq update && sudo apt-get -qq install anydesk
sayOK
fi

if ! isCommand code; then
	echo -e "\n--> Install VS Code"
	wget -q "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64" -O ~/vscode.deb && sudo dpkg -i ~/vscode.deb && rm ~/vscode.deb
sayOK
fi

if ! isCommand docker; then
	echo -e "\n--> Install Docker"
	sudo apt-get -qq install apt-transport-https gnupg-agent
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
	sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
	sudo apt-get -qq install docker-ce docker-ce-cli containerd.io
	sudo usermod -aG docker "${USER}"
sayOK
fi

if ! isCommand docker-compose; then
	echo -e "\n--> Install Docker-Compose"
	sudo apt-get -qq install libffi-dev
	sudo pip install docker-compose
	sudo service docker enable && sudo service docker start

	if [ ! -f /etc/rsyslog.d/01-blocklist.conf ]; then
		echo -e 'if $msg contains "run-docker-runtime" and $msg contains ".mount: Succeeded." then { stop }' | sudo tee -a /etc/rsyslog.d/01-blocklist.conf >/dev/null
		sudo service rsyslog restart
	fi
sayOK
fi
