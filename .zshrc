# 環境の確認
# uname -s: Print the kernel name
# uname -r: Print the kernel release
# uname -m: Print the machine hardware name
case `uname -srm` in
	*Darwin*) export KANKYO="MAC" ;; # macOS
	*microsoft*) export KANKYO="WSL" ;; # Windows 上の WSL
	*) export KANKYO="UNKNOWN" ;;
esac

# 日本語を使用
export LANG="ja_JP.UTF-8"
export LC_ALL="ja_JP.UTF-8"

# ホスト名
export HOST=$(uname -n)

export PATH="${HOME}/bin:${HOME}/opt:${HOME}/.local/bin:/opt:/snap/bin:$PATH"

# ====================
# GNU Source-highlight
export LESS='--RAW-CONTROL-CHARS --QUIET --long-prompt --HILITE-UNREAD --tabs=4'

[ -d /usr/share/source-highlight/ ] && export LESSOPEN='| /usr/share/source-highlight/src-hilite-lesspipe.sh %s'
# ====================


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

#############################
# 関数
#############################

function isCommand() {
	command -v $1 &> /dev/null
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

# 設定ファイル編集
alias zshrc="$EDITOR ~/.zshrc"
alias profile="$EDITOR ~/.zshrc"

# sudo でもエイリアスを使えるようにする
alias sudo="sudo "

# グローバルエイリアス
alias -g L="| less"

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

	function aptfresh() {
		echo "*** Update ***\n"
		sudo apt-get update
		echo -e "\n*** Upgrade ***\n"
		sudo apt-get --quiet -y upgrade
		echo -e "\n*** AutoRemove ***\n"
		sudo apt-get --quiet -y autoremove
	}
fi

# micro エディター
isCommand micro && alias m="micro "

# 設定ファイル再読み込み
alias z="source ~/.zshrc"

# 直前 (前回のセッション含む) にいたディレクトリに移動する
alias c="cdr"
alias ..="cd ../"

# ls
if [[ $KANKYO = "MAC" ]]; then
	alias sl="ls -lhO@ -v"
	alias ls="ls -Gv"
else  # Linux and other UNIX systems
	alias sl="/bin/ls --escape --classify --color --group-directories-first -cv --human-readable --almost-all -l"
	alias ls="/bin/ls --escape --classify --color=auto --group-directories-first -cv"
fi
alias l="ls"

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
if [[ $KANKYO = "MAC" ]]; then  # macOS
	! isCommand bat && alias man="man -P 'less -Rq'"
else # Linux and other Unix-like systems
	! isCommand bat && alias man="man --pager 'less --RAW-CONTROL-CHARS --QUIET'"
fi

# =====
# シンボリックリンク作成時に既に同名があれば末尾に数字 (.~1~) を付けてバックアップする
alias ln="ln --backup=numbered"

# This function checks if the target file already exists.
# If it does, the function creates a numbered backup copy before running the ln command.
if [[ $KANKYO = "MAC" ]]; then
    # Custom logic for macOS, since --backup=numbered is not supported
	my_ln() {
		if [[ -e $2 ]]; then
			counter=1
			while [[ -e "$2.$counter" ]]; do
				((counter++))
			done
			cp "$2" "$2.$counter"
		fi
		ln "$@"
	}
	alias ln=my_ln
fi
# =====

# ディレクトリツリー
# -h: ファイルサイズを人間に読みやすく
# -F: ディレクトリの後ろに / をつける
# -C: 色をつける
#  --du: フォルダーサイズも併記する
isCommand tree && alias tree="tree -hFC --du --dirsfirst"

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

if isCommand bat; then
	function tailbat() { sudo tail -f $* | bat --paging=never -l log }
	alias bat="bat --theme=Coldark-Dark --map-syntax='*rc:INI' --map-syntax='*.conf:INI' "
	alias cat="bat "
	alias -g B="| bat"
	alias -g C="| bat"
	export MANPAGER="sh -c 'col -bx | bat -l man -p'"
fi

# apt では batcat という名前でインストールされる
if isCommand batcat; then
	function tailbat() { sudo tail -f $* | batcat --paging=never -l log }
	alias bat="batcat --theme=Coldark-Dark --map-syntax='*rc:INI' --map-syntax='*.conf:INI' "
	alias cat="batcat "
	alias -g B="| batcat"
	alias -g C="| batcat"
	export MANPAGER="sh -c 'col -bx | batcat -l man -p'"
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

isCommand fdfind && eval "$(dircolors -b)"
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
if [ -f ~/.fzf.zsh -o -f /usr/share/doc/fzf/examples/completion.zsh ]; then
	[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
	[ -f /usr/share/doc/fzf/examples/completion.zsh ] && source /usr/share/doc/fzf/examples/completion.zsh
	[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && source /usr/share/doc/fzf/examples/key-bindings.zsh

	# export FZF_DEFAULT_OPTS="--height 40% --multi --exact --reverse --ansi --cycle --prompt='▶' --bind '?:toggle-preview'"
	export FZF_DEFAULT_OPTS="--height 40% --multi --exact --reverse --ansi --cycle --prompt='▶'"

	# tmux を使用中であればその機能を利用する
	export FZF_TMUX=1

	# コマンド履歴検索のオプション
	export FZF_CTRL_R_OPTS="--no-multi --preview-window down:3:hidden:wrap"

	# 現在地以下のファイル検索のオプション
	# fd (fdfind) を使うとき
	if isCommand fdfind; then
		export FZF_DEFAULT_COMMAND="fdfind --type file --hidden --color=always"
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
[ -d /opt/homebrew/share/zsh-syntax-highlighting ] && source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
