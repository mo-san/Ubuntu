# 環境の確認
case `uname --kernel-name --kernel-release --machine` in
	*raspi*) export KANKYO="PI" ;; # Raspberry Pi
	*microsoft*) export KANKYO="WSL" ;; # Windows 上の WSL
	*iPad*) export KANKYO="IOS" ;; # iPad
	*MANJARO*) export KANKYO="MANJARO" ;; # mabox or manjaro
	*) export KANKYO="UNKNOWN" ;;
esac
[ ! -z $(printenv ANDROID_ROOT) ] && export KANKYO="ANDROID" # Android 上の Termux

if [[ $KANKYO = "PI" ]] && [[ -z "${SSH_CONNECTION}" ]]; then
	export LANG=C # ラズパイに直接ログインしているなら英語ロケール
else
	export LANG=ja_JP.UTF-8 # それ以外なら日本語を使用
fi

# ホスト名
export HOST=`uname --nodename`

# if [ $KANKYO = "PI" -o $KANKYO = "WSL"  -o $KANKYO = "MANJARO" ]; then
case $KANKYO in
	"PI"|"WSL"|"MANJARO")
		# 各言語のパッケージマネージャーのパスを通す
		export PATH="/usr/local/go/bin:${HOME}/go:${HOME}/go/bin:${HOME}/.cargo/bin:/usr/local/rbenv/bin:$PATH"

		export GOPATH="${HOME}/go"
esac
# fi

export PATH="${HOME}/bin:${HOME}/opt:${HOME}/.local/bin:/opt:/snap/bin:$PATH"

# ディスプレイ出力がなくてもあるように見せかける
# export DISPLAY=
# case KANKYO in
# 	"PI") export DISPLAY=192.168.0.3:0.0 ;;
# 	"WSL") export DISPLAY=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'):0.0 ;;
# esac

# GNU Source-highlight
export LESS='--RAW-CONTROL-CHARS --QUIET --long-prompt --HILITE-UNREAD --tabs=4'
[ -d /usr/share/source-highlight/ ] && export LESSOPEN='| /usr/share/source-highlight/src-hilite-lesspipe.sh %s'


# チートシート
# command cat <<- EOS
# 	=================================================================
# 	'zshrc' or 'profile': edit profile ('edit ~/.zshrc').

# 	=== bash commands ===
# 	"bindkey" でキーバインドの一覧が見れる
# 	| key |        command       | key |          command       |
# 	|:---:| :------------------: |:---:| :--------------------: |
# 	| ^a  | 行頭                 | ^p  | それで始まる以前の履歴 |
# 	| ^b  | 次の履歴             | ^q  | 行全体を削除           |
# 	| ^d  | delete-char-or-list  | ^r  | (過去への)逐次検索     |
# 	| ^e  | 行末                 | ^s  | (未来への)逐次検索     |
# 	| ^f  | forward-char         | ^t  | transpose-chars        |
# 	| ^h  | backward-delete-char | ^u  | 行全体を切り取り       |
# 	| ^i  | タブ補完             | ^v  | 貼り付け               |
# 	| ^j  | エンター             | ^w  | backward-kill-word     |
# 	| ^k  | kill-line            | ^x  | kill-line              |
# 	| ^l  | clear-screen         | ^y  | 切り取ったのを貼り付け |
# 	| ^n  | down-line-or-history | ^/  | やり直し               |
# 	| M-q | 今の入力を退避       |
# 	EOS

if [ $KANKYO = "PI" -o $KANKYO = "WSL" -o $KANKYO = "MANJARO" ]; then
command cat <<- EOS
	【fzf 検索】 !i 最上位, ^t 現在地, ^r 履歴, 末尾「**<タブ>」 / "^music .mp3$ foo !exc", "^core go$ | rb$ | py$"
	EOS
fi

#############################
# 関数
#############################

function isCommand() {
	command -v $1 &> /dev/null
}

# フォルダーを作成したあとそこに移動する
function mkcd() {
	if [[ -d $1 ]]; then
		echo "$1 already exists!"
		cd $1
	else
		mkdir -p $1 && cd $1
	fi
}

# ディレクトリを移動したときに実行される
function chpwd() {
	# ファイル数が多くなければ ls
	if [ $(/bin/ls -1U . | wc --lines) -le 50 ]; then
		/bin/ls --escape --classify --color --group-directories-first --format=horizontal -m .
	fi
}

# ターミナルのタイトルを設定する
case $TERM in
	xterm*)
		precmd () {
			local __pwd
			case $PWD in
				"/") __pwd="" ;;
				$HOME) __pwd="~" ;;
				# 最後の/までを削除
				# Zsh 変数メモ -  https://gist.github.com/sho-t/d9cdf8271b3de7c4238739e523490542
				*) __pwd=${PWD##*/} ;;
			esac
			print -Pn "\e]0;${__pwd}/ - @${HOST} (${KANKYO})\a"
		}
	;;
esac

# 以下の条件をすべて満たすものだけをヒストリに追加する
# - line 変数
#     この関数はコマンドライン全体が引数になって、それには末尾の改行も含まれている。それでは扱いにくいので、最初の line ってとこで改行を捨てて line 変数に格納している。
# - cmd 変数
#     cmd 変数にはコマンドラインのうち最初のスペース以降を捨てた文字列が入っている。つまり、引数とかを捨てた、先頭のコマンド名の部分になる。
# - ${#line} ってとこ
#     ${#line} ってのは line 文字列の文字数になる。ここでは4文字以下の短いコマンドラインはヒストリに追加しないようにしてる。
zshaddhistory() {
	local line=${1%%$'\n'}
	local cmd=${line%% *}
	local param=${line##* }

	# ${#line} -ge 2 &&
	[[ ${line} != (?:sudo *)?reboot.* \
	&& ${cmd} != (~|\.\./?) \
	&& ${cmd} != (exit) \
	&& ${cmd} != (z|\.|source) \
#	&& ${param} != (H|L|--help|(\| *)?less) \
	]]
}

#############################
# エイリアス
#############################
# エディター設定
export EDITOR="nano"
# if   isCommand micro; then export EDITOR="micro"
# elif isCommand ne;    then export EDITOR="ne"
# fi

# 設定ファイル編集
alias zshrc="$EDITOR ~/.zshrc"
alias profile="$EDITOR ~/.zshrc"

# sudo でもエイリアスを使えるようにする
alias sudo="sudo "

# グローバルエイリアス
alias -g L="| less"
alias -g H=" --help"
alias -g V=" --version"
# isCommand xsel && alias -g C="| xsel --input --clipboard"

# apt 短縮形
if isCommand apt; then
	alias aptinstall="sudo apt install -y"
	alias aptin="aptinstall"

	alias aptinstalled="dpkg --list | grep ^i"
	alias aptls="aptinstalled"

	alias aptremove="sudo apt remove"
	alias aptrm="aptremove"

	alias aptsearch="sudo apt search --names-only"
	alias aptsc="aptsearch"

	alias aptup="sudo apt update"

	alias aptupgrade="sudo apt upgrade"
	alias aptupgr="aptupgrade"

	aprfresh() {
		echo "*** Update ***\n"
		sudo apt-get update
		echo -e "\n*** Upgrade ***\n"
		if [ "$1" = "-y" ]
		then sudo apt-get --quiet -y upgrade
		else sudo apt-get --quiet upgrade
		fi
		echo -e "\n*** AutoRemove ***\n"
		sudo apt-get --quiet -y autoremove
	}
fi

if [ $KANKYO = "MANJARO" ]; then
	alias pacinstall="sudo pacman -S"
	alias pacin="pacinstall"

	alias pacinstalled="pacman -Q"
	alias pacls="pacinstalled"

	alias pacremove="sudo pacman -Rs"
	alias pacrm="pacremove"

	alias pacsearch="sudo pacman -Ss" # 名前だけは？
	alias pacsc="pacsearch"

	alias pacup="sudo pacman -Sy"

	alias pacupgrade="sudo pacman -Syu"
	alias pacupgr="pacupgrade"

	alias pacautoremove="sudo pacman -Qdtq | sudo pacman -Rs -"

	pacfresh() {
		echo -e "*** Update & Upgrade ***\n"
		if [ "$1" = "-y" ]
		then sudo pacman -Syu --noconfirm
		else sudo pacman -Syu
		fi
	}
fi

# 複数ファイルのmv
# 例: zmv *.txt *.txt.bk
alias zmv="noglob zmv -W"

# micro エディター
isCommand micro && alias m="micro "

# 設定ファイル再読み込み
alias z="source ~/.zshrc"

# 直前 (前回のセッション含む) にいたディレクトリに移動する
alias c="cdr"
alias ..="cd ../"

# historyに日付を表示
#alias h="fc -lt '%F %T' 1"

# ls
alias sl="ls --escape --classify --color --group-directories-first -cv --human-readable --almost-all -l"
alias l="ls --escape --classify --color --group-directories-first -cv"
alias ls="l"

# コピーの上書き前に確認する
alias cp="cp -i"

# フォルダー作成の際、中間のフォルダーも作成する
alias mkdir="mkdir -p"

# ファイル検索は 大文字小文字無視、正規表現
isCommand locate && alias locate="locate -ir"

# grep で大文字小文字無視、Perl互換正規表現
alias grep="grep -iP"

# less を見やすくし、ビープ音を止める
alias less="less --QUIET --LINE-NUMBERS --long-prompt --HILITE-UNREAD --tabs=4"

# man の表示に使う less でもビープ音を止める
! isCommand bat && alias man="man --pager 'less --RAW-CONTROL-CHARS --QUIET'"

# シンボリックリンク作成時に既に同名があれば末尾に数字 (.~1~) を付けてバックアップする
alias ln="ln --backup=numbered"

# ディレクトリツリー
isCommand tree && alias tree="tree -ahFC --du --dirsfirst"

# "crontab -r" したときに確認を出す
alias crontab="crontab -i"

# 常にグローバルのpipを使う
# alias pip="sudo pip "

# diff の出力形式
# --unified: unified形式
# --context: context形式
# --side-by-side --left-column: side-by-side形式かつ、共通部分は左側にのみ表示する
alias diff="diff --side-by-side --suppress-common-lines --report-identical-files"

# trash-cli https://github.com/andreafrancia/trash-cli
# 削除の代わりにごみ箱に入れる
# ごみ箱の場所: ~/.local/share/Trash/
# ごみ箱から戻す: trash-restore
# ごみ箱一覧: trash-list
isCommand trash && alias rm="trash "

isCommand batcat && alias bat="batcat "
if isCommand bat; then
	function tailbat() { sudo tail -f $* | bat --paging=never -l log }
	alias bat="bat --theme=Coldark-Dark --map-syntax='*rc:INI' --map-syntax='*.conf:INI' "
	alias cat="bat "
	alias -g B="| bat"
	alias -g C="| bat"
	export MANPAGER="sh -c 'col -bx | bat -l man -p'"
fi

# ディスク占有率を視覚的に表示するコマンド
isCommand ncdu && alias ncdu="ncdu -x --confirm-quit"

# fd (fdfind): 高速な find
isCommand fdfind && alias fdfind="fdfind -E /mnt/ "
isCommand fdfind && alias fd="fdfind -E /mnt/ "

# ranger ファイルマネージャー
isCommand ranger && alias r="ranger "


#############################
# 補完
#############################

# "~hoge" が特定のパス名に展開されるようにする（ブックマークのようなもの）
# 例： cd ~hoge と入力すると /long/path/to/hogehoge ディレクトリに移動
#hash -d hoge=/long/path/to/hogehoge

autoload -Uz colors && colors # 色を使用
autoload -Uz compinit && compinit # 補完
autoload -U bashcompinit && bashcompinit # bash用の自動補完を使えるように

HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt share_history # 他のターミナルと履歴を共有
setopt extended_history # 履歴に時間を記録する
setopt hist_ignore_all_dups # 履歴に重複を表示しない
setopt hist_no_store # historyコマンドは履歴に登録しない
setopt hist_reduce_blanks # ヒストリに保存するときに余分なスペースを削除する
setopt hist_verify # 履歴を呼び出してから実行する間に一旦編集可能

cdpath=(~) # どこからでも移動できるディレクトリパス
setopt auto_cd # cdコマンドを省略して、ディレクトリ名のみの入力で移動
setopt auto_pushd # 自動でpushdを実行
setopt pushd_ignore_dups # pushdから重複を削除

setopt no_beep # beep を無効にする
setopt no_promptcr # 出力の文字列末尾に改行コードがなくても表示
setopt ignore_eof # Ctrl+Dでzshを終了しない
setopt interactive_comments # '#' 以降をコメントとして扱う
setopt no_flow_control # Ctrl+sのロック, Ctrl+qのロック解除を無効にする

setopt auto_param_keys # カッコの対応などを自動的に補完
setopt auto_param_slash # ディレクトリ名の補完で末尾の / を自動的に付ける

# 区切り文字の設定
autoload -Uz select-word-style
select-word-style default
zstyle ':zle:*' word-chars "_-./;@"
zstyle ':zle:*' word-style unspecified


zstyle ':completion:*:default' menu select=2 # 補完後、メニュー選択モードになり左右キーで移動が出来る

# ../ の後は今いるディレクトリを補完しない
zstyle ':completion:*' ignore-parents parent pwd ..

zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete _correct _approximate
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
eval "$(dircolors -b)"
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' menu select=long
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' verbose true
zstyle ':completion:*' list-dirs-first true
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

# 補完で大文字にもマッチ
# まずそのまま試し、次に小文字と大文字を同一視し、「.-_」があれば無視してみる。
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' '+m:{A-Z}={a-z}' 'r:|[._-]=* r:|=* l:|=*'

bindkey -e # emacsキーバインド

# 使わないキーバインドを解除する
# bindkey -r '^m' # accept-line
bindkey -r '^O' # accept-line-and-send-break
bindkey -r '^G' # send-break
bindkey -r '^@' # set-mark-command

# Ctrl+rでヒストリーのインクリメンタルサーチ、Ctrl+sで逆順
bindkey '^r' history-incremental-pattern-search-backward
bindkey '^s' history-incremental-pattern-search-forward

# コマンドを途中まで入力後、historyから絞り込み
# 例 ls まで打ってCtrl+pでlsコマンドをさかのぼる、Ctrl+bで逆順
autoload -Uz history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^p" history-beginning-search-backward-end
bindkey "^b" history-beginning-search-forward-end
bindkey "^x" kill-line
# cdrコマンドを有効 ログアウトしても有効なディレクトリ履歴
# cdr タブでリストを表示
autoload -Uz add-zsh-hook
autoload -Uz chpwd_recent_dirs cdr
add-zsh-hook chpwd chpwd_recent_dirs
# cdrコマンドで履歴にないディレクトリにも移動可能に
zstyle ":chpwd:*" recent-dirs-default true

autoload -Uz zmv # 複数ファイルのmv

# backspace,deleteキーを使えるように
stty erase ^H
bindkey "^[[3~" delete-char

# Home, End キー
bindkey "\e[1~" beginning-of-line
bindkey "\e[4~" end-of-line
bindkey "^[[H" beginning-of-line
bindkey "^[[F" end-of-line

# Escキー
bindkey "^[" kill-whole-line

# Ctrl-矢印キー
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word
bindkey "\e[1;5C": forward-word
bindkey "\e[1;5D": backward-word
bindkey "\e[5C": forward-word
bindkey "\e[5D": backward-word
bindkey "\e\e[C": forward-word
bindkey "\e\e[D": backward-word
# bindkey "^[[1;5C" vi-forward-blank-word
# bindkey "^[[1;5D" vi-backward-blank-word

#############################
# プロンプト
#############################

# 256色カラーチャート
# https://upload.wikimedia.org/wikipedia/commons/1/15/Xterm_256color_chart.svg
# 256色ワンライナー
# for c in {000..255}; do echo -n "\e[38;5;${c}m $c" ; [ $(($c%16)) -eq 15 ] && echo;done;echo

RESET="%{%f%k%}"
LPROMPT2="%{%F{007}%K{067}%}%(!.#.>)" # lightgrey on blue
RPROMPT1="%{%F{178}%K{237}%} %D{%Y-%m-%d %H:%M:%S}" # orange on grey

case ${(L)HOST} in # 変数をすべて小文字に変換する
	"raspberrypi")
		LPROMPT1="%{%F{007}%K{067}%}%d" # white on blue
		RPROMPT2="%{%F{237}%K{217}%} %n@%m" # grey (#3a3a3a) on lightpink (#ffafaf)
		;;
	"adastra")
		LPROMPT1="%{%F{237}%K{217}%}%d" # grey on pink
		RPROMPT2="%{%F{007}%K{067}%} %n@%m" # lightgrey (#c0c0c0) on blue (#5f87af)
		;;
	"aipatsudo"|"air")
		LPROMPT1="%{%F{238}%K{193}%}%d" # grey on yellowgreen
		RPROMPT2="%{%F{235}%K{228}%} %n@%m" # grey (#262626) on lightyellow ("ffff87")
		;;
	"asus")
		LPROMPT1="%{%F{238}%K{193}%}%d" # grey on yellowgreen
		RPROMPT2="%{%F{235}%K{228}%} %n@%m" # grey (#262626) on lightyellow ("ffff87")
		;;
	"lenovo")
		LPROMPT1="%{%F{238}%K{193}%}%d" # grey on yellowgreen
		RPROMPT2="%{%F{235}%K{228}%} %n@%m" # grey (#262626) on lightyellow ("ffff87")
		;;
	*)
		LPROMPT1="%{%F{238}%K{254}%}%d" # grey
		RPROMPT2="%{%F{253}%K{233}%} %n@%m" # grey (#dadada) on #121212
		;;
esac

PROMPT=`echo "${LPROMPT1}\n${LPROMPT2}${RESET}"`
RPROMPT=`echo "${RPROMPT1} ${RPROMPT2} ${RESET}\n"`
unset RESET LPROMPT1 LPROMPT2 RPROMPT1 RPROMPT2

#############################
# ほか
#############################
# キーバインド設定
# eval "xmodmap ~/.Xmodmap"

# 音量指定(メッセージを出さない)
# eval "amixer -q set Master 10%"

#====================
# fzf (fuzzy finder)
#====================
# 更新コマンド: cd ~/bin/fzf && git pull && ./install
if [ -f ~/.fzf.zsh -o -f /usr/share/fzf/completion.zsh ]; then
	[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
	[ -f /usr/share/fzf/completion.zsh ] && source /usr/share/fzf/completion.zsh
	[ -f /usr/share/fzf/key-bindings.zsh ] && source /usr/share/fzf/key-bindings.zsh

	export FZF_DEFAULT_OPTS="--height 40% --multi --exact --reverse --ansi --cycle --prompt='▶' --bind '?:toggle-preview'"

	# tmux を使用中であればその機能を利用する
	export FZF_TMUX=1

	# コマンド履歴検索のオプション
	export FZF_CTRL_R_OPTS="--no-multi --preview-window down:3:hidden:wrap"

	# 現在地以下のファイル検索のオプション
	# fd (fdfind) を使うとき
	if isCommand fdfind; then
		export FZF_DEFAULT_COMMAND="fdfind --type file --color=always"
		export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
	else
		export FZF_CTRL_T_COMMAND="find -L ${RBUFFER} -mindepth 1 \\( -path '*/node_modules/*' -o -path '*/TRASH/*' -o -path '*/\\.*' \
			-o -fstype 'sysfs' -o -fstype 'devfs' -o -fstype 'devtmpfs' -o -fstype 'proc' \\) -prune \
			-o -type f -print  -o -type d -print  -o -type l -print 2> /dev/null | cut -b3-"
	fi
	# (長いが、行を折り返すとエラーになる)
	export FZF_CTRL_T_OPTS="--preview '[[ {} =~ \.(png|jpg|gif|pyc|save)$ ]] || /usr/share/source-highlight/src-hilite-lesspipe.sh {} || (highlight -O ansi -l {} || cat {} || tree -L 3 -hFC {}) 2> /dev/null | head -200'"

	# 現在地以下のフォルダーへ移動のオプション
	export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -200'"

	# ALT-I - locate での検索結果を取り出す
	fzf-locate-widget() {
		local selected
		if selected=$(locate / | fzf -q "$LBUFFER"); then
			LBUFFER=$selected
		fi
		zle redisplay
	}
	__fzf_use_tmux__() {
		[ -n "$TMUX_PANE" ] && [ "${FZF_TMUX:-0}" != 0 ] && [ ${LINES:-40} -gt 15 ]
	}

	__fzfcmd() {
		__fzf_use_tmux__ && echo "fzf-tmux -d${FZF_TMUX_HEIGHT:-40%}" || echo "fzf"
	}

	alias h="history -i 1 | $(__fzfcmd) --tac --no-sort | sed -re 's/^ *[0-9]+ *[0-9-]{10} [0-9:]+ *//'"
	zle     -N    fzf-locate-widget
	bindkey '\ei' fzf-locate-widget
fi

#====================
# docker-compose 補完
#====================
fpath=(~/.zsh/completion $fpath)
autoload -Uz compinit && compinit -i

#====================
# zsh-Syntax-Highlighting
# https://github.com/zsh-users/zsh-syntax-highlighting
#====================
[ -d /usr/share/zsh-syntax-highlighting ] && source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
[ -d /usr/share/zsh/plugins/zsh-syntax-highlighting ] && source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
