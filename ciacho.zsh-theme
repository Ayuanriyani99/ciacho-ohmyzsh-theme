# vim:ft=zsh ts=2 sw=2 sts=2
#
# Ciacho Theme 
# https://github.com/Ciacho/ciacho-ohmyzsh-theme
#
# agnoster's Theme - https://gist.github.com/3712874
# A Powerline-inspired theme for ZSH
#
# # README
#
# In order for this theme to render correctly, you will need a
# [Powerline-patched font](https://github.com/Lokaltog/powerline-fonts).
# Make sure you have a recent version: the code points that Powerline
# uses changed in 2012, and older versions will display incorrectly,
# in confusing ways.
#
# In addition, I recommend the
# [Solarized theme](https://github.com/altercation/solarized/) and, if you're
# using it on Mac OS X, [iTerm 2](http://www.iterm2.com/) over Terminal.app -
# it has significantly better color fidelity.
#
# # Goals
#
# The aim of this theme is to only show you *relevant* information. Like most
# prompts, it will only show git information when in a git working directory.
# However, it goes a step further: everything from the current user and
# hostname to whether the last call exited with an error to whether background
# jobs are running in this shell will all be displayed automatically when
# appropriate.


alias ta='tmux -CC attach -t'
alias tad='tmux -CC attach -d -t'
alias ts='tmux -CC new-session -s'

CIACHO_VERSION="1.1a"

### Segment drawing
# A few utility functions to make it easy and re-usable to draw segmented prompts

CURRENT_BG='NONE'
PRIMARY_FG=black

SEGMENT_SEPARATOR="\ue0b0 "

PLUSMINUS="\u00b1 "
BRANCH="\ue0a0 "
BRANCH_BEGIN="‹ "
BRANCH_END="› "
DETACHED="\u27a6 "
CROSS="\u2718 "
LIGHTNING="\u26a1 "
GEAR="\u2699 "


# Begin a segment
# Takes two arguments, background and foreground. Both can be omitted,
# rendering default background/foreground.
prompt_segment() {
  local bg fg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
  if [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]; then
    print -n " %{$bg%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR%{$fg%} "
  else
    print -n "%{$bg%}%{$fg%} "
  fi
  CURRENT_BG=$1
  [[ -n $3 ]] && print -n $3
}

# End the prompt, closing any open segments
prompt_end() {
  if [[ -n $CURRENT_BG ]]; then
    print -n "%{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
  else
    print -n "%{%k%}"
  fi
  print -n "%{%f%}"
  CURRENT_BG=''
}

function prompt_ciacho_battery() {
	if [[ $(uname) == "Darwin" ]] ; then
		if [[ $(ioreg -rc AppleSmartBattery | grep -c '^.*"ExternalConnected"\ =\ No') -eq 1 ]] ; then
			b=$(battery_pct)
      if [ $b -gt 50 ] ; then
        prompt_segment green white
      elif [ $b -gt 20 ] ; then
        prompt_segment yellow white
      else
        prompt_segment red white
      fi
			print  -n "$fg_bold[white]$LIGHTNING$(battery_pct_remaining)%%$fg_no_bold[white]"
		fi
# Problem with acpi - debug in future
# elif [[ $(uname) == "Linux" ]]; then
#		function battery_is_charging() {
#			! [[ $(acpi 2&>/dev/null | grep -c '^Battery.*Discharging') -gt 0 ]]
#		}
#
#		function battery_pct() {
#			if (( $+commands[acpi] )) ; then
#				echo "$(acpi | cut -f2 -d ',' | tr -cd '[:digit:]')"
#      fi
#    }
#
#    function battery_pct_remaining() {
#      if [ ! $(battery_is_charging) ] ; then
#        battery_pct
#      else
#        echo "External Power"
#      fi
#    }
#
#    function battery_time_remaining() {
#      if [[ $(acpi 2&>/dev/null | grep -c '^Battery.*Discharging') -gt 0 ]] ; then
#        echo $(acpi | cut -f3 -d ',')
#      fi
#    }
#
#    b=$(battery_pct_remaining)
#    if [[ $(acpi 2&>/dev/null | grep -c '^Battery.*Discharging') -gt 0 ]] ; then
#      if [ $b -gt 40 ] ; then
#        prompt_segment green white
#      elif [ $b -gt 20 ] ; then
#        prompt_segment yellow white
#      else
#        prompt_segment red white
#      fi
#     print  -n "$fg_bold[white]$LIGHTNING $(battery_pct_remaining)%%$fg_no_bold[white]"
#    fi
	fi
}



#prompt_ciacho_git() {
#  local color ref
#  is_dirty() {
#    test -n "$(git status --porcelain --ignore-submodules)"
#  }
#  ref="$vcs_info_msg_0_"
#  if [[ -n "$ref" ]]; then
#    if is_dirty; then
#      color=yellow
#      ref="${ref} $PLUSMINUS"
#    else
#      color=green
#      ref="${ref} "
#    fi
#    if [[ "${ref/.../}" == "$ref" ]]; then
#      ref="$BRANCH_BEGIN $BRANCH $ref $BRANCH_END"
#    else
#      ref="$DETACHED ${ref/.../}"
#    fi
#    prompt_segment $color $PRIMARY_FG
#    print -Pn " $ref"
#  fi
#}

prompt_ciacho_git() {
  local ref dirty mode repo_path clean has_upstream
  local modified untracked added deleted tagged stashed
  local ready_commit git_status bgclr fgclr
  local commits_diff commits_ahead commits_behind has_diverged to_push to_pull

  repo_path=$(git rev-parse --git-dir 2>/dev/null)

  if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
    dirty=$(parse_git_dirty)
    git_status=$(git status --porcelain 2> /dev/null)
    ref=$(git symbolic-ref HEAD 2> /dev/null) || ref="➦ $(git rev-parse --short HEAD 2> /dev/null)"
    if [[ -n $dirty ]]; then
      clean=''
      bgclr='yellow'
      fgclr='magenta'
    else
      clean=' ✔'
      bgclr='green'
      fgclr='white'
    fi

    local upstream=$(git rev-parse --symbolic-full-name --abbrev-ref @{upstream} 2> /dev/null)
    if [[ -n "${upstream}" && "${upstream}" != "@{upstream}" ]]; then has_upstream=true; fi

    local current_commit_hash=$(git rev-parse HEAD 2> /dev/null)

    local number_of_untracked_files=$(\grep -c "^??" <<< "${git_status}")
    # if [[ $number_of_untracked_files -gt 0 ]]; then untracked=" $number_of_untracked_files◆"; fi
    if [[ $number_of_untracked_files -gt 0 ]]; then untracked=" $number_of_untracked_files☀"; fi

    local number_added=$(\grep -c "^A" <<< "${git_status}")
    if [[ $number_added -gt 0 ]]; then added=" $number_added $CROSS"; fi

    local number_modified=$(\grep -c "^.M" <<< "${git_status}")
    if [[ $number_modified -gt 0 ]]; then
      modified=" $number_modified●"
      bgclr='red'
      fgclr='white'
    fi

    local number_added_modified=$(\grep -c "^M" <<< "${git_status}")
    local number_added_renamed=$(\grep -c "^R" <<< "${git_status}")
    if [[ $number_modified -gt 0 && $number_added_modified -gt 0 ]]; then
      modified="$modified$((number_added_modified+number_added_renamed))±"
    elif [[ $number_added_modified -gt 0 ]]; then
      modified=" ●$((number_added_modified+number_added_renamed))±"
    fi

    local number_deleted=$(\grep -c "^.D" <<< "${git_status}")
    if [[ $number_deleted -gt 0 ]]; then
      deleted=" $number_deleted‒"
      bgclr='red'
      fgclr='white'
    fi

    local number_added_deleted=$(\grep -c "^D" <<< "${git_status}")
    if [[ $number_deleted -gt 0 && $number_added_deleted -gt 0 ]]; then
      deleted="$deleted$number_added_deleted±"
    elif [[ $number_added_deleted -gt 0 ]]; then
      deleted=" ‒$number_added_deleted $PLUSMINUS"
    fi

    local tag_at_current_commit=$(git describe --exact-match --tags $current_commit_hash 2> /dev/null)
    if [[ -n $tag_at_current_commit ]]; then tagged=" ☗$tag_at_current_commit "; fi

    local number_of_stashes="$(git stash list -n1 2> /dev/null | wc -l)"
    if [[ $number_of_stashes -gt 0 ]]; then
      stashed=" $number_of_stashes $GEAR"
      bgclr='magenta'
      fgclr='white'
    fi

    if [[ $number_added -gt 0 || $number_added_modified -gt 0 || $number_added_deleted -gt 0 ]]; then ready_commit=' ⚑'; fi

    local upstream_prompt=''
    if [[ $has_upstream == true ]]; then
      commits_diff="$(git log --pretty=oneline --topo-order --left-right ${current_commit_hash}...${upstream} 2> /dev/null)"
      commits_ahead=$(\grep -c "^<" <<< "$commits_diff")
      commits_behind=$(\grep -c "^>" <<< "$commits_diff")
      upstream_prompt="$(git rev-parse --symbolic-full-name --abbrev-ref @{upstream} 2> /dev/null)"
      upstream_prompt=$(sed -e 's/\/.*$/ ☊ /g' <<< "$upstream_prompt")
    fi

    has_diverged=false
    if [[ $commits_ahead -gt 0 && $commits_behind -gt 0 ]]; then has_diverged=true; fi
    if [[ $has_diverged == false && $commits_ahead -gt 0 ]]; then
      if [[ $bgclr == 'red' || $bgclr == 'magenta' ]] then
        to_push=" $fg_bold[white]↑$commits_ahead$fg_bold[$fgclr]"
      else
        to_push=" $fg_bold[black]↑$commits_ahead$fg_bold[$fgclr]"
      fi
    fi
    if [[ $has_diverged == false && $commits_behind -gt 0 ]]; then to_pull=" $fg_bold[magenta]↓$commits_behind$fg_bold[$fgclr]"; fi

    if [[ -e "${repo_path}/BISECT_LOG" ]]; then
      mode=" <B>"
    elif [[ -e "${repo_path}/MERGE_HEAD" ]]; then
      mode=" >M<"
    elif [[ -e "${repo_path}/rebase" || -e "${repo_path}/rebase-apply" || -e "${repo_path}/rebase-merge" || -e "${repo_path}/../.dotest" ]]; then
      mode=" >R>"
    fi

    prompt_segment $bgclr $fgclr

    print -n "$fg_bold[$fgclr]${ref/refs\/heads\//$BRANCH_BEGIN $BRANCH $upstream_prompt}${mode}$to_push$to_pull$clean$tagged$stashed$untracked$modified$deleted$added$ready_commit$fg_no_bold[$fgclr] $BRANCH_END"
  fi
}

# Dir: current working directory
prompt_ciacho_dir() {

local _max_pwd_length="60"
  if [[ $(echo -n $PWD | wc -c) -gt ${_max_pwd_length} ]]; then
    prompt_segment cyan white "$fg_bold[white]%-2~ ... %3~$fg_no_bold[white] "
  else
  	prompt_segment cyan white "$fg_bold[white]%~$fg_no_bold[white] "
  fi
}


# Context: user@hostname (who am I and where am I)
prompt_ciacho_context() {

  if [[ $(whoami) == root && $(uname) == Darwin ]]; then
    prompt_segment yellow magenta "$fg_bold[white]%(!.%{%F{white}%}.)@$USER$fg_no_bold[white]"
  elif [[ $(whoami) == root ]]; then
    prompt_segment red black "$fg_bold[white]%(!.%{%F{white}%}.)$USER@$fg_bold[magenda]%(!.%{%F{magenda}%}.)%m$fg_no_bold[magenda]"
	elif [[ $(uname) == Darwin ]]; then
    prompt_segment cyan white "$fg_bold[white]%(!.%{%F{white}%}.)@$USER$fg_no_bold[white]"
	elif [[ -n "$SSH_CLIENT" ]]; then
    prompt_segment black white "$fg_bold[white]%(!.%{%F{white}%}.)$USER@$fg_bold[yellow]%(!.%{%F{yellow}%}.)%m$fg_no_bold[yellow]"
	else
    prompt_segment magenta white "$fg_bold[white]%(!.%{%F{white}%}.)@$USER$fg_no_bold[white]"
	fi 
}

prompt_ciacho_hash() {
	if [[ $(whoami) == root ]]; then
		prompt_segment red $PRIMARY_FG "%#"
  else 
		prompt_segment blue $PRIMARY_FG "%#" 
	fi
}

prompt_ciacho_time() {
  prompt_segment blue white "$fg_bold[white]%D{%H:%M}$fg_no_bold[white]"
}


# Virtualenv: current working virtualenv
prompt_ciacho_virtual() {
  local virtualenv_path="$VIRTUAL_ENV"
  if [[ -n $virtualenv_path && -n $VIRTUAL_ENV_DISABLE_PROMPT ]]; then
    prompt_segment blue black "(`basename $virtualenv_path`)"
	elif [[ -f /etc/vps ]]; then
    prompt_segment blue black "[VPS]"
  fi
}

# SSH
prompt_ciacho_ssh() {
  local sshenv="$SSH_CLIENT"
  if [[ -n $sshenv  ]]; then
		if [[ $(whoami) == root ]]; then
			prompt_segment blue red "[SSH]"
		else
	    prompt_segment blue black "[SSH]"
		fi
  fi
}


prompt_ciacho_main() {
	RETVAL=$?
	print -n "\n"
	prompt_ciacho_battery
	prompt_ciacho_time
	prompt_ciacho_ssh
	prompt_ciacho_context
  prompt_ciacho_git
  prompt_ciacho_dir
  prompt_end
  CURRENT_BG='NONE'
  print -n "\n"
  prompt_ciacho_hash
  prompt_end

}


prompt_ciacho_precmd() {
  vcs_info
  PROMPT='%{%f%b%k%}$(prompt_ciacho_main) '
}


prompt_ciacho_setup() {
  autoload -Uz add-zsh-hook
  autoload -Uz vcs_info

  prompt_opts=(cr subst percent)

  add-zsh-hook precmd prompt_ciacho_precmd

  zstyle ':vcs_info:*' enable git
  zstyle ':vcs_info:*' check-for-changes false
  zstyle ':vcs_info:git*' formats '%b'
  zstyle ':vcs_info:git*' actionformats '%b (%a)'
}

prompt_ciacho_setup "$@"


