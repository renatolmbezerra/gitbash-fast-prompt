# gitbash-fast-prompt

Prompt personalizado para Git Bash no Windows, sem processos extras a cada Enter.

## O que mostra

SO, usuário, host, memória, remote e branch do git, versão do Python e status do venv (vermelho inativo, verde ativo).

## Por que é rápido

Tudo é lido com builtins do bash, sem `wmic`, `python --version` ou `git`:

- Memória: `/proc/meminfo`
- Python: `pyvenv.cfg` do venv ou arquivo de versão do pyenv
- Git: `.git/HEAD` e `.git/config`

Em testes, o prompt caiu de ~9,6 s para ~0,13 s.

## Instalação

```bash
cp ~/.bashrc ~/.bashrc.bak
cp bashrc ~/.bashrc
source ~/.bashrc
```

## Requisitos

Git Bash (Git for Windows) e uma fonte com suporte a emojis.
