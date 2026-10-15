# Detecta o SO uma única vez ($OSTYPE é variável interna do bash, não abre processo)
case "$OSTYPE" in
    linux*)              __OS_EMOJI="🐧"; __VENV_BIN="bin" ;;
    darwin*)             __OS_EMOJI="🍎"; __VENV_BIN="bin" ;;
    msys*|cygwin*|win*)  __OS_EMOJI="🪟"; __VENV_BIN="Scripts" ;;
    *)                   __OS_EMOJI="❓"; __VENV_BIN="bin" ;;
esac

# Auto-activate .venv ao entrar no diretório
auto_activate_venv() {
    if [ -d ".venv" ] && [ -z "$VIRTUAL_ENV" ]; then
        echo "Activating virtual environment (.venv)..."
        source ".venv/$__VENV_BIN/activate"
    fi
}

auto_deactivate_venv() {
    if [ -n "$VIRTUAL_ENV" ]; then
        echo "Deactivating virtual environment..."
        deactivate
    fi
}

cd() {
    builtin cd "$@" && auto_activate_venv
}

# Memória: lê /proc/meminfo só com builtins (zero processos)
__update_mem() {
    local k v total=0 free=0 avail=0
    while read -r k v _; do
        case $k in
            MemTotal:)     total=$v ;;
            MemFree:)      free=$v ;;
            MemAvailable:) avail=$v ;;
        esac
    done < /proc/meminfo 2>/dev/null
    (( avail > 0 )) && free=$avail
    if (( total > 0 )); then
        local u=$(( (total - free) * 10 / 1048576 )) t=$(( total * 10 / 1048576 ))
        printf -v __MEM "%d.%dG/%d.%dG" $((u/10)) $((u%10)) $((t/10)) $((t%10))
    else
        __MEM="N/A"
    fi
}

# Python: lê a versão de arquivos, sem executar python (zero processos)
__PY_VENV="__init__"; __PY_DIR="__init__"
__update_python() {
    [[ "$VIRTUAL_ENV" == "$__PY_VENV" && "$PWD" == "$__PY_DIR" ]] && return
    __PY_VENV=$VIRTUAL_ENV; __PY_DIR=$PWD; __PY="?"
    local k v
    if [[ -n $VIRTUAL_ENV && -f $VIRTUAL_ENV/pyvenv.cfg ]]; then
        while IFS=' =' read -r k v; do
            [[ $k == version || $k == version_info ]] && { __PY=${v%%.final*}; break; }
        done < "$VIRTUAL_ENV/pyvenv.cfg"
    elif [[ -f .python-version ]]; then
        read -r __PY < .python-version
    elif [[ -f ~/.pyenv/pyenv-win/version ]]; then
        read -r __PY < ~/.pyenv/pyenv-win/version
    fi
}

# Git: lê .git/HEAD e .git/config direto (zero processos)
__update_git() {
    __GIT_BRANCH="No Branch"; __GIT_REMOTE="No Remote"
    local d=$PWD gitdir head line in_origin=0
    while [[ -n $d && ! -e $d/.git ]]; do d=${d%/*}; done
    [[ -z $d ]] && return
    gitdir=$d/.git
    if [[ -f $gitdir ]]; then              # worktree/submódulo: .git é um arquivo
        read -r line < "$gitdir"; gitdir=${line#gitdir: }
        [[ $gitdir != /* ]] && gitdir=$d/$gitdir
    fi
    read -r head < "$gitdir/HEAD" 2>/dev/null || return
    if [[ $head == "ref: refs/heads/"* ]]; then
        __GIT_BRANCH=${head#ref: refs/heads/}
    else
        __GIT_BRANCH=${head:0:7}           # HEAD destacado: mostra o hash curto
    fi
    [[ -f $gitdir/config ]] || return
    while IFS= read -r line; do
        line=${line#"${line%%[![:space:]]*}"}
        case $line in
            '[remote "origin"]') in_origin=1 ;;
            '['*)                in_origin=0 ;;
            url*=*) (( in_origin )) && { line=${line#*=}; __GIT_REMOTE=${line# }; break; } ;;
        esac
    done < "$gitdir/config"
}

# Monta o prompt
update_prompt() {
    __update_mem
    __update_git
    __update_python

    # venv: vermelho quando inativo, verde quando ativo
    local venv_status='\[\e[38;5;202m\]🔴 venv inactive'
    [[ -n $VIRTUAL_ENV ]] && venv_status='\[\e[38;5;46m\]🟢 venv active'

    PS1='\[\e[38;5;45m\]'"$__OS_EMOJI"' \u \[\e[38;5;208m\]💻 @\h \[\e[38;5;220m\]🧠 '"$__MEM"' \[\e[38;5;82m\]🌐 '"$__GIT_REMOTE"' \[\e[38;5;226m\]['"$__GIT_BRANCH"'] \[\e[38;5;129m\]🐍 Python '"$__PY"' '"$venv_status"' \[\e[38;5;33m\]📁 \w\n\[\e[38;5;15m\]➜ '
}

# Carregar variáveis do .env automaticamente ao abrir o terminal
if [ -f .env ]; then
    set -a
    source <(grep -v '^\s*#' .env | tr -d '\r')
    set +a
fi

PROMPT_COMMAND=update_prompt

