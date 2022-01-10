#!/usr/bin/env bash
# bash /mnt/g/マイドライブ/Ubuntu/ubuntu_on_wsl_setup.sh

usernameWin='Me'
GoogleDrive='/mnt/g/マイドライブ'

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

echo -e "\n--> setting locale as Japanese"
	sudo locale-gen ja_JP.UTF-8
	sudo update-locale LANG=ja_JP.UTF-8
	echo "LANG=ja_JP.UTF-8" | sudo tee /etc/default/locale

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
	python-setuptools \
	python3-pip \
	source-highlight \
	tree \
	unar \
	unzip \
	xsel \
	zsh \
	zsh-syntax-highlighting
sayOK

echo -e "\n--> Deploying home directory contents"
	cp -rv $GoogleDrive/Ubuntu/home/. ~/

echo -e "\n--> [installing] app on pip"
	sudo pip3 install --upgrade pip
	sudo pip3 install --quiet \
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

echo -e "\n--> creating symlinks for the ease of access to C and D drive"
	if [ ! -d /c/ ]; then
		sudo ln -s /mnt/c/ /c
	fi
	if [ -d /mnt/d/ ] && [ ! -d /d/ ]; then
		sudo ln -s /mnt/d/ /d
	fi
	if ! grep -q "[automount]" /etc/wsl.conf; then
		echo -e "[automount]\noptions = \"metadata,umask=22,fmask=111\"" | sudo tee -a /etc/wsl.conf
	fi

echo -e "\n--> Install ansible-related packages"
	if [ ! -f ~/.ansible/ansible.log ]; then
		mkdir -p ~/.ansible
		touch ~/.ansible/ansible.log
	fi
	if ! pip3 list | awk '{print $1}' | grep -q "^ansible$"; then
		pip3 install ansible
	fi
	if ! pip3 list | awk '{print $1}' | grep -q "^jmespath$"; then
		# JSONのフィルタリングに必要
		pip3 install jmespath
	fi
	if ! dpkg -l | grep "^.i" | awk '{print $2}' | grep -q "^sshpass"; then
		# --ask-pass を使うときに必要
		sudo apt-get install -y sshpass
	fi

	if isCommand ansible-galaxy; then
		ansible-galaxy collection install ansible.posix
		ansible-galaxy collection install community.general
	fi
	if [ ! -f ~/.ansible.cfg ]; then
		cp -v $GoogleDrive/Ubuntu/.ansible.cfg ~/.ansible.cfg
	fi

	### ansible の実行方法:
	# cd /mnt/g/マイドライブ/Ubuntu/ansible; ansible-playbook -i hosts.yml playbook.yml -v --tags pisetup --check
