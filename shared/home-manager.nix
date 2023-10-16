{ config, pkgs, lib, ... }:

let name = "Anuj More";
    user = "atm";
    email = "anujmorex@gmail.com"; in
{
  alacritty = {
    enable = true;
    settings = {
      cursor = {
        style = "Block";
      };

      window = {
        opacity = 1.0;
        padding = {
          x = 24;
          y = 24;
        };
      };

      font = {
        normal = {
          family = "MesloLGS NF";
          style = "Regular";
        };
        size = lib.mkMerge [
          (lib.mkIf pkgs.stdenv.hostPlatform.isLinux 10)
          (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin 14)
        ];
      };

      dynamic_padding = true;
      decorations = "full";
      title = "Terminal";
      class = {
        instance = "Alacritty";
        general = "Alacritty";
      };

      colors = {
        primary = {
          background = "0x1f2528";
          foreground = "0xc0c5ce";
        };

        normal = {
          black = "0x1f2528";
          red = "0xec5f67";
          green = "0x99c794";
          yellow = "0xfac863";
          blue = "0x6699cc";
          magenta = "0xc594c5";
          cyan = "0x5fb3b3";
          white = "0xc0c5ce";
        };

        bright = {
          black = "0x65737e";
          red = "0xec5f67";
          green = "0x99c794";
          yellow = "0xfac863";
          blue = "0x6699cc";
          magenta = "0xc594c5";
          cyan = "0x5fb3b3";
          white = "0xd8dee9";
        };
      };
    };
  };

  bat = {
    enable = true;
    config = {
      pager = "less -FR";
      theme = "TwoDark";
    };
  };

  bottom = {
    enable = true;
    settings = {
      flags = {
        avg_cpu = true;
        temperature_type = "c";
      };

      colors = {
        low_battery_color = "red";
      };
    };
  };

  broot.enable = true;

  direnv.enable = true;

  emacs = {
    enable = true;
    package = pkgs.emacs29;
  };

  eza = {
    enable = true;
    enableAliases = true;
    extraOptions = [
      "--group-directories-first"
      "--header"
    ];
    git = true;
    icons = true;
  };

  fzf.enable = true;

  git = {
    enable = true;
    userName = name;
    userEmail = email;
    delta.enable = true;
    lfs.enable = true;
    aliases = {
      st = "status";
      ca = "commit -a";
      br = "branch";
      ds = "diff --staged";
      unstage = "reset HEAD";
      uncommit = "reset --soft HEAD^";
      diffw = "diff --color --color-words --abbrev";
      lp = "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit -p";
      sync = "remote update origin --prune";
      pl = "merge --ff-only @{u}";
      forget="! /usr/local/bin/git fetch -p && /usr/local/bin/git branch -vv | awk '/: gone]/{print $1}' | xargs /usr/local/bin/git branch -D";
    };
    ignores = [
      "*~"
      "*.swp"
      "*.swo"
      ".bundle"
      "zeus.json"
      ".DS_Store"
    ];
    extraConfig = {
      init.defaultBranch = "dev";
      
      core = { 
        # fsmonitor = true;
        autocrlf = "input";
      };
      feature.manyFiles = true;
      pull.rebase = true;
      push.autoSetupRemote = true;
      rebase.autoStash = true;
      url = {
        "ssh://git@gitlab.myteksi.net:" = {
          insteadOf = "https://gitlab.myteksi.net/";
        };
      };
    };
  };

  htop.enable = true;

  java.enable = true;

  jq.enable = true;

  k9s = {
    enable = true;
    settings = {
      refreshRate = 2;
    };
  };

  kitty = {
    enable = true;
  };

  less = {
    enable = true;
  };

  navi = {
    enable = true;
    settings = {
      cheats = {
        paths = [
          "~/cheats/"
        ];
      };
    };
  };

  neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimdiffAlias = true;
    withNodeJs = true;
    withPython3 = true;
    withRuby = true;
  };

  # nix-index.enable = true;

  noti.enable = true;

  pet.enable = true;

  ripgrep.enable = true;

  sioyek = {
    enable = true;
    bindings = {
      "move_up" = "k";
      "move_down" = "j";
      "move_left" = "h";
      "move_right" = "l";
      "screen_down" = [ "J" "<C-d>" ];
      "screen_up" = [ "K" "<C-u>" ];
    };
    config = {
      "background_color" = "1.0 1.0 1.0";
      "text_highlight_color" = "1.0 0.0 0.0";
    };
  };

  ssh = {
    enable = true;

    extraConfig = lib.mkMerge [
      ''
        Host github.com
          Hostname github.com
          IdentitiesOnly yes
      ''
      (lib.mkIf pkgs.stdenv.hostPlatform.isLinux
        ''
          IdentityFile /home/${user}/.ssh/github
        '')
      (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin
        ''
          IdentityFile /Users/${user}/.ssh/github
        '')
    ];
  };

  tmux = {
    enable = true;
    plugins = with pkgs.tmuxPlugins; [
      vim-tmux-navigator
      sensible
      yank
      prefix-highlight
      {
        plugin = power-theme;
        extraConfig = ''
           set -g @tmux_power_theme 'gold'
        '';
      }
      {
        plugin = resurrect; # Used by tmux-continuum

        # Use XDG data directory
        # https://github.com/tmux-plugins/tmux-resurrect/issues/348
        extraConfig = ''
          set -g @resurrect-dir '$HOME/.cache/tmux/resurrect'
          set -g @resurrect-capture-pane-contents 'on'
          set -g @resurrect-pane-contents-area 'visible'
        '';
      }
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '5' # minutes
        '';
      }
    ];
    terminal = "screen-256color";
    prefix = "C-a";
    escapeTime = 10;
    historyLimit = 50000;
    extraConfig = ''
      # Remove Vim mode delays
      set -g focus-events on

      # Start indexing from 1
      set -g base-index 1
      set -g pane-base-index 1
      set-window-option -g pane-base-index 1
      set-option -g renumber-windows on

      # Enable full mouse support
      set -g mouse on

      # -----------------------------------------------------------------------------
      # Key bindings
      # -----------------------------------------------------------------------------

      # Unbind default keys
      unbind C-b
      unbind '"'
      unbind %

      # Split panes, vertical or horizontal
      bind-key x split-window -v -c "#{pane_current_path}" 
      bind-key v split-window -h -c "#{pane_current_path}"

      # Move around panes with vim-like bindings (h,j,k,l)
      bind-key -n M-k select-pane -U
      bind-key -n M-h select-pane -L
      bind-key -n M-j select-pane -D
      bind-key -n M-l select-pane -R

      # Smart pane switching with awareness of Vim splits.
      # This is copy paste from https://github.com/christoomey/vim-tmux-navigator
      is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
        | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$'"
      bind-key -n 'C-h' if-shell "$is_vim" 'send-keys C-h'  'select-pane -L'
      bind-key -n 'C-j' if-shell "$is_vim" 'send-keys C-j'  'select-pane -D'
      bind-key -n 'C-k' if-shell "$is_vim" 'send-keys C-k'  'select-pane -U'
      bind-key -n 'C-l' if-shell "$is_vim" 'send-keys C-l'  'select-pane -R'
      tmux_version='$(tmux -V | sed -En "s/^tmux ([0-9]+(.[0-9]+)?).*/\1/p")'
      if-shell -b '[ "$(echo "$tmux_version < 3.0" | bc)" = 1 ]' \
        "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\'  'select-pane -l'"
      if-shell -b '[ "$(echo "$tmux_version >= 3.0" | bc)" = 1 ]' \
        "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\\\'  'select-pane -l'"

      bind-key -T copy-mode-vi 'C-h' select-pane -L
      bind-key -T copy-mode-vi 'C-j' select-pane -D
      bind-key -T copy-mode-vi 'C-k' select-pane -U
      bind-key -T copy-mode-vi 'C-l' select-pane -R
      bind-key -T copy-mode-vi 'C-\' select-pane -l
      '';
  };

  vim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [
      fzf-vim
      vim-airline
      vim-airline-themes
      vim-startify
      vim-tmux-navigator
    ];
    settings = { ignorecase = true; };
    extraConfig = ''
      "" General
      set number
      set history=1000
      set nocompatible
      set modelines=0
      set encoding=utf-8
      set scrolloff=3
      set showmode
      set showcmd
      set hidden
      set wildmenu
      set wildmode=list:longest
      set cursorline
      set ttyfast
      set nowrap
      set ruler
      set backspace=indent,eol,start
      set laststatus=2
      set clipboard=autoselect

      " Dir stuff
      set nobackup
      set nowritebackup
      set noswapfile
      set backupdir=~/.config/vim/backups
      set directory=~/.config/vim/swap

      " Relative line numbers for easy movement
      set relativenumber
      set rnu

      "" Whitespace rules
      set tabstop=8
      set shiftwidth=2
      set softtabstop=2
      set expandtab

      "" Searching
      set incsearch
      set gdefault

      "" Statusbar
      set nocompatible " Disable vi-compatibility
      set laststatus=2 " Always show the statusline
      let g:airline_theme='bubblegum'
      let g:airline_powerline_fonts = 1

      "" Local keys and such
      let mapleader=","
      let maplocalleader=" "

      "" Change cursor on mode
      :autocmd InsertEnter * set cul
      :autocmd InsertLeave * set nocul

      "" File-type highlighting and configuration
      syntax on
      filetype on
      filetype plugin on
      filetype indent on

      "" Paste from clipboard
      nnoremap <Leader>, "+gP

      "" Copy from clipboard
      xnoremap <Leader>. "+y

      "" Move cursor by display lines when wrapping
      nnoremap j gj
      nnoremap k gk

      "" Map leader-q to quit out of window
      nnoremap <leader>q :q<cr>

      "" Move around split
      nnoremap <C-h> <C-w>h
      nnoremap <C-j> <C-w>j
      nnoremap <C-k> <C-w>k
      nnoremap <C-l> <C-w>l

      "" Easier to yank entire line
      nnoremap Y y$

      "" Move buffers
      nnoremap <tab> :bnext<cr>
      nnoremap <S-tab> :bprev<cr>

      "" Like a boss, sudo AFTER opening the file to write
      cmap w!! w !sudo tee % >/dev/null

      "" Ctrl-P
      nnoremap <c-p> :Files<cr>

      let g:startify_lists = [
        \ { 'type': 'dir',       'header': ['   Current Directory '. getcwd()] },
        \ { 'type': 'sessions',  'header': ['   Sessions']       },
        \ { 'type': 'bookmarks', 'header': ['   Bookmarks']      }
        \ ]

      let g:startify_bookmarks = [
        \ '~/.local/share/src',
        \ ]

      let g:airline_theme='bubblegum'
      let g:airline_powerline_fonts = 1
      '';
  };

  yazi.enable = true;

  yt-dlp.enable = true;

  # Shared shell configuration
  zsh = {
    enable = true;
    autocd = false;
    cdpath = [ "~/.local/share/src" ];
    plugins = [
      {
          name = "powerlevel10k";
          src = pkgs.zsh-powerlevel10k;
          file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
      {
          name = "powerlevel10k-config";
          src = lib.cleanSource ./config;
          file = "p10k.zsh";
      }
    ];
    initExtraFirst = ''
      if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
        . /nix/var/nix/profiles/default/etc/profile.d/nix.sh
      fi

      # Define variables for directories
      export PATH=$PATH:/opt/homebrew/bin
      export PATH=$HOME/.local/share/bin:$PATH
      export PATH=$HOME/bin:$PATH

      export GOPATH=$HOME/gopath
      export GOBIN="$HOME/gopath/bin"
      export PROTO_PATH=${pkgs.protobuf}
      export PATH=$PATH:$PROTO_PATH/bin

      export HOMEBREW_NO_ANALYTICS=1

      export EDITOR="vim"
      export VISUAL="vim"

      # Always color ls and group directories
      alias ls='ls --color=auto'
    '';
  };

  zoxide = {
    enable = true;
    options = [
      "--cmd j"
    ];
  };
}
