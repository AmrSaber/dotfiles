local ret_status="%(?:%{$FG[032]%}➜ :%{$fg_bold[red]%}➜ %s)"
PROMPT=$'%{$FG[032]%}%/ $(git_prompt_info)%{$fg_bold[blue]%} % %{$reset_color%}
${ret_status}%{$reset_color%}'

PROMPT2="%{$fg_blod[black]%}%_> %{$reset_color%}"

ZSH_THEME_GIT_PROMPT_PREFIX="(%{$fg[red]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY="%{$FG[032]%}) %{$fg[yellow]%}✗%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$FG[032]%})"
