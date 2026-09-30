# `dev` vs `old` — what differs between the two branches

Written 2026-09-29 against this checkout (`/home/atm/_code/nixos-config`), re-measured 2026-10-01
against `dev` after the cleanup commit.

| | branch `old` | branch `dev` |
| --- | --- | --- |
| commit | `52ccbf3` — "Snapshot of execat/nixos-config-private@903b536 (branch dev), history squashed" | `9de1bcc` — "Remove unnecessary files" (on top of `53a6560` "Stop Baloo error message" and `11f2844` "Office suites") |
| what it is | the private GitHub repo `execat/nixos-config-private`, `dev` branch @ `903b536` ("Fix package names after reference bump"), squashed to a single commit so it can be diffed locally | the working branch |
| history | 1 commit, no parents, no remote | local history, no remote configured |
| tracked files | 44 | 60 (69 before `9de1bcc` removed 10 and the docs were added back) |

The two branches share no ancestry, so `git diff old dev` compares trees only. `old` carries
the tree of the remote's `dev`, `dev` is the local rewrite — the diff below is "what changed
in the restructure", not a series of edits.

```sh
git diff --stat old dev            # 94 files changed, 6542 insertions(+), 5809 deletions(-)
git diff --name-status -M -C old dev   # 51 A, 35 D, 2 M, 6 renames
git diff -M old dev -- <path>
git show old:<path> / git show dev:<path>
```

---

## 1. The shape of the repo changed

`old` is a flat, hand-grown layout; `dev` is a restructured tree with an explicit
`hosts/` + `modules/` split, flake `apps` instead of `bin/` scripts, and secrets stored
in-repo. `dev` is visibly built on the `dustinlyons/nixos-config` starter template (the
`apps/*/apply` scripts, `%USER%/%NAME%/%EMAIL%/%HOST%/%DISK%` placeholders, the
`modules/{shared,nixos,darwin}` docs and the emacs `init.el` all come from it);
`old` was the user's own config on an unrelated layout.

| | `old` | `dev` |
| --- | --- | --- |
| top level | `arch/ bin/ darwin/ nixos/ overlays/ shared/` + `flake.nix` `flake.lock` `README.md` `.gitignore` `update-nixpkgs.sh` | `apps/ hosts/ modules/ overlays/ secrets/` + `flake.nix` `flake.lock` `agenix-rules.nix` `README.md` |
| per-OS config | `nixos/`, `darwin/`, `arch/` (each a flat bag of `default/packages/files/home-manager/secrets.nix`) | `hosts/<os>/<host>/` (identity: hostname, disks, stateVersion, secrets) + `modules/<os>/` (reusable config) + `modules/shared/` |
| entry points | `bin/` shell scripts | flake `apps.<system>.<name>` wrapping `apps/<system>/<name>` scripts |
| secrets | separate private flake input `execat/nix-secrets` | `secrets/*.age` in-repo + `agenix-rules.nix` + host-key identity |
| docs | one root README, one per OS dir | `hosts/nixos/mokpo/{README,SECRETS}.md`, `modules/nixos/{README,DESKTOP}.md`, `modules/{shared,darwin}/README.md`, `secrets/README.md`, `overlays/README.md`, `README.md` |

Change volume by top-level directory (`git diff --numstat -M -C old dev`):

```
apps         files=12   +863    -0
arch         files=5    +0      -104
bin          files=5    +0      -166
darwin       files=5    +0      -556
hosts        files=7    +988    -0
modules      files=33   +3940   -467
nixos        files=7    +0      -479
overlays     files=1    +30     -0
(root)       files=7    +655    -202
secrets      files=2    +66     -0
shared       files=10   +0      -3835
```

(`shared` is the largest deletion: `shared/config/` alone is −3653 lines, mostly
`emacs/config.org` and the old `init.el`.)

### 1.1 File-move map (renames git could detect, plus the rest)

| `old` | `dev` | similarity |
| --- | --- | --- |
| `darwin/README.md` | `modules/darwin/README.md` | 100% |
| `darwin/files.nix` | `modules/darwin/files.nix` | 70% |
| `darwin/packages.nix` | `modules/darwin/packages.nix` | 71% |
| `darwin/default.nix` | `hosts/darwin/default.nix` | 143 → 92 lines, +32/−83 |
| `darwin/home-manager.nix` | `modules/darwin/home-manager.nix` | +49/−69 |
| `darwin/dock/default.nix` | `modules/darwin/dock/default.nix` | reformatted (nixfmt), same module |
| `darwin/casks.nix` | `modules/darwin/casks.nix` | both exist, contents completely different |
| `darwin/secrets.nix` | `modules/darwin/secrets.nix` | live secrets → commented stub; **deleted again in `9de1bcc`** |
| `shared/README.md` | `modules/shared/README.md` | 90% |
| `shared/home-manager.nix` | `modules/shared/home-manager.nix` | 50%, 609 → 379 lines |
| `shared/packages.nix` | `modules/shared/packages.nix` | 117 → 70 lines |
| `shared/files.nix` | `modules/shared/files.nix` | 32 → 26 lines |
| `shared/config/p10k.zsh` | `modules/shared/config/p10k.zsh` | 100% |
| `shared/config/emacs/config.org` | `modules/shared/config/emacs/config.org` | 99% (see §10) — **deleted in `9de1bcc`**, so this rename no longer appears in the diff |
| `shared/config/emacs/init.el` | `modules/shared/config/emacs/init.el` | rewritten, 86 → 234 lines |
| `nixos/{default,files,hardware-configuration,home-manager,packages,secrets}.nix` | superseded by `hosts/nixos/{default.nix,mokpo/*}` + `modules/nixos/*` | no rename detected; content largely carried over |
| `nixos/README.md` | `modules/nixos/README.md` | rewritten |
| `shared/config/emacs/init.el` | — | the old copy has no `dev` counterpart other than the rewritten one |

41 of the 44 paths in `old` are absent from `dev`; 6 of those 41 were detected as renames (the
map above), leaving 35 deleted outright (`git diff --name-status` shows them as `D`) — `arch/`
(5), `bin/` (5), `nixos/` (7), `darwin/{casks,default,dock/default,home-manager,secrets}.nix`,
`shared/{default,files,packages}.nix`, `shared/cachix/default.nix`,
`shared/config/{amethyst.yml,emacs-profiles.el,quicklisp.lisp}`,
`shared/config/emacs/{config.org,init.el,.gitignore}`, `README.md`, `.gitignore`,
`update-nixpkgs.sh`. `overlays/README.md` is the one path that survives byte-identical.

Added in `dev` (51 paths): `agenix-rules.nix`, `apps/**` (12: the 3 Linux scripts, 4 + 4 darwin
scripts, and the `apps/aarch64-linux` symlink), `hosts/**` (7), `modules/**` (33, including
`modules/nixos/config/{polybar/*.ini,rofi/*.rasi}` and a 708 KB `login-wallpaper.png`),
`secrets/{README.md,github-ssh-key.age}`, `overlays/10-feather-font.nix`, and
`diff-branches-dev-old.md` (this file).

---

## 2. `flake.nix` and `flake.lock`

### 2.1 Inputs

| input | `old` | `dev` |
| --- | --- | --- |
| `nixpkgs` | pinned rev `github:nixos/nixpkgs?rev=523257564973361cc3e55e3df3e77e68c20b0b80` ("25th Jan 2026"), bumped by `update-nixpkgs.sh` | `github:nixos/nixpkgs/nixos-unstable` (branch tracking; lock has `f5c082a40f`) |
| `agenix` | same | same |
| `home-manager` | `follows nixpkgs` | *no longer* follows nixpkgs (`home-manager.url` only) — this is what lets `nixpkgs_3` into the lock, and it is why the Intel Mac's user config stopped evaluating (§11.5) |
| `darwin` | `LnL7/nix-darwin/master`, `follows nixpkgs` | same URL; lock now resolves to the `nix-darwin/nix-darwin` org |
| `nix-homebrew` | `github:zhaofengli/nix-homebrew` | `github:zhaofengli-wip/nix-homebrew` |
| `homebrew-core`, `homebrew-cask` | present | present |
| `homebrew-bundle` | — | **new** (`github:homebrew/homebrew-bundle`, `flake = false`) |
| `disko` | present, `follows nixpkgs` | same |
| `secrets` | **`git+ssh://git@github.com/execat/nix-secrets.git`, `flake = false`** | **removed** (replaced by in-repo `secrets/`, §4) |
| `systems` (transitive) | locked node exists | gone |

`flake.lock`: 78 insertions / 82 deletions. Nodes dropped: `systems`, `secrets`. Nodes added:
`homebrew-bundle`, `nixpkgs_3`. Every input's `rev` moved:

| input | old rev | dev rev |
| --- | --- | --- |
| nixpkgs | `59e69648d3` | `f5c082a40f` |
| agenix | `fcdea22339` | `9353cb2936` |
| darwin | `43975d782b` | `c3e90c8964` |
| disko | `00395d188e` | `725ea35e41` |
| home-manager | `abfad3d295` | `a6631107a8` |
| nix-homebrew | `6a8ab60bfd` | `c11cccfdd3` |
| homebrew-bundle | — | `a3265c84b2` |
| secrets | `f8678ef0a5` (`refs/heads/dev`) | — |

`update-nixpkgs.sh` (the `curl`-GitHub-API + `sed` flake.nix rev bumper) is deleted: `dev`
tracks the `nixos-unstable` branch instead of a pinned rev.

### 2.2 Outputs

| output | `old` | `dev` |
| --- | --- | --- |
| `devShells` | per-system `mkShell` with `bashInteractive git age age-plugin-yubikey`, empty `shellHook` | same inputs, `shellHook` now `export EDITOR=vim` |
| `apps` | — | **new**: `mkApp` wrapper per system — `apply`, `build-switch`, `clean` on Linux; `apply`, `build`, `build-switch`, `clean` on darwin (§5) |
| `darwinConfigurations` | one: `macos` = `x86_64-darwin` | `genAttrs` over `aarch64-darwin` + `x86_64-darwin` (attribute names are the platform names) |
| homebrew taps | `taps = {}`, `mutableTaps = true`, `autoMigrate = true` | taps pinned to the `homebrew-core`/`-cask`/`-bundle` inputs, `mutableTaps = false`, `autoMigrate = true` |
| `nixosConfigurations` | one: `nixos` (x86_64-linux) | `mokpo` + `x86_64-linux` (alias of the same system) + `starter` (`x86_64-linux`) + `aarch64-linux`, from two builders: `mokpoSystem` (no disko; the machine owns its own disks) and `starterSystem` (disko + home-manager, placeholder disk) |
| `homeConfigurations` | `arch` = home-manager `./arch` on x86_64-linux | **gone** (with `arch/`) |
| `specialArgs` | `inputs` only | `inputs // { user, gitName, gitEmail, inputs }` — the values `apps/*/apply` used to `sed` in as `%USER%/%NAME%/%EMAIL%` |
| home-manager wiring | inline in `flake.nix`: `useGlobalPkgs`, `useUserPackages`, `home-manager.users.atm = import ./nixos/home-manager.nix`, `backupFileExtension = ".bak"` | lives in `modules/nixos/desktop.nix`: same two flags, `backupFileExtension = "backup"`, `overwriteBackup = true`, `extraSpecialArgs = { user, gitName, gitEmail }`, `users.atm = import ./modules/nixos/home-manager.nix` |
| systems list | `[ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" ]` | split into `linuxSystems` (adds `aarch64-linux`) and `darwinSystems` |
| description | "Starter Configuration for NixOS and MacOS" | "Starter Configuration with secrets for MacOS and NixOS" |

`flake.nix` grew 124 → 141 lines (148 before `9de1bcc` dropped the six dangling app declarations).

---

## 3. `shared/` → `modules/shared/`

The same module, heavily trimmed and re-pointed at the starter's idioms.

### 3.1 `home-manager.nix` (609 → 379 lines, similarity 50%)

Signature: `{ config, pkgs, lib, ... }` (with `name`/`user`/`email` hardcoded in a `let`)
→ `{ config, pkgs, lib, user, gitName, gitEmail, ... }`.

Programs **removed** (present in `old`, gone in `dev`):
`alacritty` was `enable = false` (now `true`), `bat`, `bottom`, `broot`, `direnv`
(+`nix-direnv`), `emacs`, `eza`, `fzf`, `delta`, `htop`, `java`, `jq`, `k9s`, `kitty`,
`less`, `navi`, `neovim`, `noti`, `pet`, `ripgrep`, `yazi`, `yt-dlp`, `atuin`, `starship`,
`zoxide`.
Programs **kept/added**: `zsh`, `git`, `vim`, `alacritty`, `ssh`, `tmux`, plus
`zellij.enable = true` (new).

| area | `old` | `dev` |
| --- | --- | --- |
| `zsh` | `autocd = true`, `syntaxHighlighting`/`autosuggestion` on, plugins `zsh-completions` + a GitHub-fetched `zsh-ai-commands`, GOPATH/GEM_HOME/HOMEBREW_* env, emacs profile aliases, `source ~/.zshrc.local` | `autocd = false`, `cdpath = [ "~/Projects" ]`, plugins `powerlevel10k` + `./config/p10k.zsh`, PATH/pnpm aliases, `EDITOR=emacsclient -t`, no zshrc.local |
| prompt | `starship` (large inline config) | powerlevel10k (config file carried over) |
| `git` | `user.name/email` hardcoded, 11 aliases (`st`, `ca`, `br`, `ds`, `unstage`, `uncommit`, `diffw`, `lp`, `sync`, `pl`, `forget`), `init.defaultBranch = "dev"`, `feature.manyFiles`, `push.autoSetupRemote`, a `gitlab.myteksi.net` insteadOf, ignores `*~ *.swp *.swo .bundle zeus.json .DS_Store` | no aliases, `init.defaultBranch = "main"`, `commit.gpgsign = true`, `pull.rebase`/`rebase.autoStash`, ignores `*.swp` only |
| git identity | `Anuj More <anujmorex@gmail.com>` | `gitName`/`gitEmail` from `specialArgs` = `Anuj More <anujmorex+nixos@gmail.com>` |
| `ssh` | `programs.ssh.matchBlocks` with `lib.mkMerge`/`mkIf` per platform, `homelab`/`homelab2` matchBlocks, `AddKeysToAgent`, github key at `~/.ssh/github` | `programs.ssh.settings` (the current option) with `lib.optionals`, `includes` `~/.ssh/config_external`, `SendEnv`/`HashKnownHosts`, github key at `~/.ssh/id_github`; the homelab blocks are gone. In-code comment explains why `mkIf` no longer works in the freeform option |
| `tmux` | base-index/pane-base-index 1, `renumber-windows on`, `-c "#{pane_current_path}"` on splits | those extra options dropped; plugins/prefix/config otherwise the same |
| `vim` | plugins included `fzf-vim`, `<c-p>` mapped to `:Files`, startify bookmark `~/.local/share/src` | `fzf-vim` and the `<c-p>` map dropped, startify bookmarks `~/Projects`, `~/Documents` |
| `alacritty` | `enable = false` ("issue on x86-64") | enabled, with `terminal.shell` pinned to the nix zsh; `dynamic_padding`/`title`/`class`/`decorations` dropped |

### 3.2 `packages.nix` (117 → 70 lines)

`old` was the "everything" list; `dev` is the starter's. 58 package entries exist only in
`old`, 29 only in `dev`.

Only in `old`: `aspell`/`aspellDicts.en`, `cachix`, `chez`, `clojure-lsp`, `cmake`,
`darkhttpd`, `elixir`/`elixir-ls`, `elmPackages.elm` (+ language server), `entr`, `fasd`,
`ffmpeg-full`, `findutils`, `fira-mono`, `fossil`, `gcc`, `ghc`, `glow`, `graphviz`,
`haskellPackages.lsp`, `leiningen`, `libyaml`, `lua5_4`/`lua-language-server`, `lynx`,
`mercurial`, `moreutils`, `neofetch`, `nginx`, `nil`, `nodejs` (unversioned),
`nodePackages.typescript*`, `opam`, `pstree`, `python313` (+`poetry-core`, `virtualenv`),
`rlwrap`, `ruby_4_0` + `rubyPackages_4_0.*`, `rust-analyzer`, `rustfmt`, `swi-prolog`,
`tokei`, `unixtools.watch`, `uv`, `w3m`, `wabt`, `yarn`, `yubikey-manager`, `elixir`, … —
i.e. the whole polyglot language toolchain and the self-hosting `nginx`/`darkhttpd`.

Only in `dev`: `alacritty`, `awscli2`, `bat`, `btop`, `direnv`, `docker`,
`docker-compose`, `emacs-all-the-icons-fonts`, `ffmpeg` (not `-full`), `fzf`, `gh`, `htop`,
`jq`, `killall`, `kubectl`, `lazygit`, `nodejs_24`, `noto-fonts`(+`-color-emoji`),
`openjdk`, `python3`, `ripgrep`, `terraform`, `tmux`, `unrar`, `unzip`, `virtualenv`,
`wget`, `zip`, `curl`, `go`, `rustc`, `cargo`, `meslo-lgs-nf`, `zsh-powerlevel10k`.

### 3.3 `files.nix` (32 → 26 lines)

| `old` | `dev` |
| --- | --- |
| `.config/amethyst/amethyst.yml` | — |
| `.config/emacs.clean/init.el` | `.emacs.d/init.el` (from `config/emacs/init.el`) |
| `.emacs.d` = `pkgs.fetchFromGitHub` chemacs2 (`plexus/chemacs2@c2d700b`) | — (chemacs profile switching dropped) |
| `.emacs-profiles.el` (profiles default/clean/clojure/doom) | — |
| `.bundle/config` (`BUNDLE_PATH: .bundle`) | — |
| — | a commented-out `getEnv` snippet; the old "point `config.org` at the emacs config" comment was rewritten in `9de1bcc` after `config.org` was deleted |

### 3.4 `default.nix`

Same overlay autodiscovery, but `allowBroken`/`allowUnsupportedSystem` flip `false → true`,
and `dev` appends an **emacs overlay fetched at evaluation time**:

```nix
++ [(import (builtins.fetchTarball {
     url = "https://github.com/dustinlyons/emacs-overlay/archive/refs/heads/master.tar.gz";
     sha256 = emacsOverlaySha256;   # let emacsOverlaySha256 = "11p1c1l04zrn8dd5w8zyzlv172z05dwi9avbckav4d5fk043m754";
   }))] 
```

For the record: `emacs-unstable`, which `hosts/darwin/default.nix` installs, does not exist in
the locked nixpkgs (`nix eval … emacs-unstable.name` → *attribute missing*), so this overlay is
what provides it. It is impure at eval time, and no NixOS host names a package from it.

### 3.5 Deleted from `shared/`

`shared/cachix/default.nix` (the `nix-community.cachix.org` substituter + its public key) is
gone; the equivalent substituter/trusted-key settings now appear in `hosts/darwin/default.nix`
and `hosts/nixos/default.nix` instead. `shared/config/{amethyst.yml,emacs-profiles.el,
quicklisp.lisp,emacs/.gitignore}` are deleted with the features that used them, and
`shared/config/emacs/config.org` was deleted later, in `9de1bcc` (§10).

---

## 4. Secrets: separate private repo → in-repo agenix

| | `old` | `dev` |
| --- | --- | --- |
| where the ciphertext lives | private repo `execat/nix-secrets`, consumed as flake input `secrets` (`git+ssh://…?ref=dev`, `flake = false`) | `secrets/*.age` in this repo (+ `agenix-rules.nix` at the root) |
| one-line state | `secrets/github-ssh-key.age` for the NixOS side, `darwin-syncthing-{cert,key}.age`, `github-signing-key.age` | `secrets/github-ssh-key.age` only |
| identity | per-user `~/.ssh/id_ed25519` (`age.identityPaths` in `nixos/secrets.nix` and `darwin/secrets.nix`) | host's own OpenSSH host keys: `/etc/ssh/ssh_host_ed25519_key` + `/etc/ssh/ssh_host_rsa_key` |
| recipients | declared inside the nix-secrets repo | `agenix-rules.nix` (the two public halves of `mokpo`'s host keys) — the file the agenix CLI reads |
| secrets declared | NixOS: `syncthing-cert`, `syncthing-key`, `github-ssh-key` → `~/.ssh/github` (group `wheel`), `github-signing-key` → `~/.ssh/pgp_github.key`. Darwin: `syncthing-{cert,key}` in `~/Library/Application Support/Syncthing/`, `github-ssh-key` → `~/.ssh/github` (symlink), `github-signing-key` | `github-ssh-key` → `/home/atm/.ssh/id_github`, `symlink = false`, `0600`, `atm:users` — in `hosts/nixos/mokpo/secrets.nix` only |
| `modules/nixos/secrets.nix`, `modules/darwin/secrets.nix` | live config | stub modules in the restructure, **deleted in `9de1bcc`** — nothing imports them any more |
| docs | none in-repo | `secrets/README.md` (CLI workflow, reinstall caveat) + `hosts/nixos/mokpo/SECRETS.md` (host-specific state, host-key fingerprints, the still-unimplemented move back to `execat/nix-secrets`, including the "root cannot fetch the private flake input" blocker and a deploy-key plan) |

Net effect: no second repo and no user age key to carry; the price (documented in both
READMEs) is that reinstalling `mokpo` generates new host keys and the existing `.age` files
stop decrypting until the new public key is added as a recipient and `agenix -r` is run.
`secrets/github-ssh-key.age` is a binary addition (0 → 1335 bytes), as is
`modules/nixos/config/login-wallpaper.png` (0 → 708 763 bytes).

---

## 5. `bin/` → flake `apps`

| `old` | `dev` equivalent |
| --- | --- |
| `bin/build` — dispatch by `uname` to one of the three below | `apps.<system>.build-switch` (`nix run .#build-switch`, `--host <name>` supported) |
| `bin/nixos-build` — `sudo SSH_AUTH_SOCK=$SSH_AUTH_SOCK nixos-rebuild switch --flake .#nixos` | `apps/x86_64-linux/build-switch` — target `x86_64-linux`/`aarch64-linux` by `uname -m`, or `--host mokpo`; same `SSH_AUTH_SOCK` pass-through |
| `bin/darwin-build` — chmod the Homebrew taps dir with `chmod +a "atm allow …"` then `sudo ./result/sw/bin/darwin-rebuild switch --flake .#macos` | `apps/{aarch64,x86_64}-darwin/build-switch` — no tap-permission dance (`mutableTaps = false` now), `sudo ./result/sw/bin/darwin-rebuild switch --flake .#<system>` |
| `bin/arch-build` — build `homeConfigurations.arch.activationPackage` and run `./result/bin/home-manager-generation` | — (the `arch` output is gone) |
| `bin/apply` — `sed` `%USER%/%EMAIL%/%NAME%` across the tree | `apps/<system>/apply` — the starter's larger version of the same idea: also asks for a GitHub user + secrets repo name, rewrites `flake.nix` to insert the `secrets` input, asks for hostname/boot disk on Linux, and `sed`s `%INTERFACE%`/`%DISK%`/`%HOST%` too. It still points at `dustinlyons/nixos-config` (the "star my repo" prompt), and its `secrets`-input insertion is stale for this repo |
| — | `apps/<system>/clean` — `nix-collect-garbage --delete-older-than 7d` (Linux also re-installs the bootloader and `df -h /boot`) |
| — | `apps/{aarch64,x86_64}-darwin/build` |
| — | ~~`apps/*-darwin/{check,copy,create}-keys`, `apps/aarch64-darwin/rollback`~~ — removed in `9de1bcc`, together with their flake declarations |

`apps/aarch64-linux` is a **symlink** to `x86_64-linux` (so the `aarch64-linux` starter host
reuses the x86 scripts, which pass `aarch64-linux` through `$FLAKE_TARGET`).

`9de1bcc` also dropped the declarations that had no script: `install`, `install-with-secrets`,
`copy-keys`, `create-keys`, `check-keys` (Linux) and darwin's `rollback`. What remains is what
exists — Linux `apply`/`build-switch`/`clean`, darwin `apply`/`build`/`build-switch`/`clean`,
which is what `nix eval .#apps.<system>` now lists.

Still open (see §11): every `apps/<system>/<name>` script is committed **mode 100644**, while
`mkApp`'s wrapper does `exec ${self}/apps/${system}/${scriptName}` — the exec fails. Verified
by running the store copy directly:

```
$ nix flake archive --json . | …            # → /nix/store/…-source
$ ls -l /nix/store/…-source/apps/x86_64-linux/
-r--r--r-- 1 root root 5444 apply
-r--r--r-- 1 root root 1196 build-switch
-r--r--r-- 1 root root  593 clean
$ bash -c "exec /nix/store/…-source/apps/x86_64-linux/clean"
bash: line 1: …/apps/x86_64-linux/clean: Permission denied
```

(`bin/*` in `old` was 100755.) Until that is fixed either way, the working invocations are
`bash apps/x86_64-linux/build-switch --host mokpo` or a one-off `chmod +x apps/*/*`.

---

## 6. NixOS: `nixos/` → `hosts/nixos/{default,mokpo}` + `modules/nixos/`

`nixos/default.nix` (208 lines) is split three ways: machine identity → `hosts/nixos/mokpo/`
`default.nix`, reusable desktop → `modules/nixos/desktop.nix`, and the template's own starter
host → `hosts/nixos/default.nix` (306 lines, still carrying `%HOST%`/`%INTERFACE%`
placeholders, `America/New_York`, disko and the `authorizedKeys` list).

`mokpo` (the real laptop, "ported from `/etc/nixos` on 2026-09-28") imports
`./hardware-configuration.nix`, `inputs.agenix.nixosModules.default`, `./secrets.nix` and
`../../../modules/nixos/desktop.nix` — deliberately **not** disko and **not**
`modules/nixos/secrets.nix` (that module no longer exists, §4).

| setting | `old` `nixos/default.nix` | `dev` `hosts/nixos/mokpo/default.nix` | `dev` starter host |
| --- | --- | --- | --- |
| hostname | `ningbo` | `mokpo` | `%HOST%` |
| time zone / locale | `Asia/Singapore`, `en_SG.UTF-8` (+ per-LC settings) | same | `America/New_York`, `en_US.UTF-8` |
| `system.stateVersion` | `25.05` | `26.05` | template default; the starter host itself is `21.05` |
| bootloader | systemd-boot, `configurationLimit = 42`, `canTouchEfiVariables` | systemd-boot, `canTouchEfiVariables` (no limit; `mokpo/README.md` suggests adding 42) | systemd-boot + `configurationLimit = 42` |
| LUKS | swap container `luks-5301882c-…` in `default.nix`, others in `hardware-configuration.nix` | `luks-a7d4c564-…` (swap) + root on `/dev/mapper/luks-93dd5e3f-…` | none (disko) |
| disks | root by UUID `5ff247ad-…`, LUKS `c4d42e6e-…`, ESP `E854-4EF3` | ESP `4F27-388E`, root on the 93dd5e3f mapper, swap on the a7d4c564 mapper (see `mokpo/README.md`) | `disk-config.nix`: `/dev/%DISK%`, GPT, 100M ESP + ext4 `/` |
| DHCP | `networking.useDHCP = false` + `interfaces.eno1.useDHCP = true` | not set (the `useDHCP` default line was dropped from `hardware-configuration.nix`); NetworkManager only | `%INTERFACE%` placeholder |
| `nix.*` | `nixPath`, `allowed-users`, `package = nixVersions.latest`, `extraOptions = experimental-features` | `nix.settings.experimental-features` only | + `substituters`/`trusted-public-keys`/`trusted-users` |
| GNOME/GTK | `programs.gnupg.agent` enabled with `pinentryPackage = lib.mkForce pkgs.pinentry-qt`, `programs.dconf.enable`, `programs.ssh.askPassword = ksshaskpass` | none of those (the gpg-agent omission is explained in `desktop.nix`: Plasma 6 and XFCE each `mkDefault` `pinentryPackage` → "defined multiple times") | `gnupg.agent.enable = true`, `dconf.enable`, `zsh.enable` |
| sessions | SDDM + KDE Plasma 6, GNOME, XFCE, awesome (with `luarocks`/`awesome-wm-widgets`), Hyprland | SDDM explicitly **off**; lightdm + slick greeter (from `desktop.nix`), bspwm as `defaultSession`; Plasma 6 and XFCE still selectable | lightdm + slick + bspwm, `none+bspwm` |
| X keyboard | `layout = "us"` (no options) | `layout = "us"`, `variant = ""` (no `ctrl:nocaps`); `desktop.nix` adds `ctrl:nocaps` | `ctrl:nocaps` |
| emacs | `services.emacs.enable = true` | not enabled (yet `bspwmrc` waits for the daemon — see `DESKTOP.md`) | commented out |
| docker | `virtualisation.docker.enable` + `logDriver = "json-file"` | not enabled | `virtualisation.docker.enable` |
| printing | CUPS + `pkgs.brlaser` | not enabled | commented out |
| syncthing | service not configured; only agenix secrets for its cert/key | not configured | `services.syncthing` enabled (dataDir/configDir, GUI on 127.0.0.1:8384, `overrideFolders/Devices`) |
| SSH keys | `users.users.{atm,root}.openssh.authorizedKeys.keys = [ <ed25519> ]` | not managed here (§11.4) | `keys = [ <same ed25519> ]` used for `atm` + `root` |
| hardware | `graphics.enable` + `enable32Bit`, `hardware.ledger.enable`, `boot.kernelModules = [ "uinput" ]`, libinput | `desktop.nix`: `graphics.enable`, `libinput`, `fonts.packages` incl. `feather-font`; kernel modules/ledger not set | `ledger.enable`, libinput, docker |
| packages | `agenix`, `gitAndTools.gitFull`, `inetutils`, `curl`, `vim`, `wget` + fonts | larger list: `emacs`, `mercurialFull`, `git`, `jujutsu`, `vim`, `uv`, `direnv`, `zellij`, `ghostty`, `bat`, `tree`, `tokei`, `sqlitebrowser`, `transmission_4-gtk`, `file`, `coreutils`, `vlc`, `kdePackages.kate`, agenix CLI, … | template list |
| extras | `services.xserver.videoDrivers = [ "intel" ]`, `services.tumbler`/`gvfs`, `security.sudo.wheelNeedsPassword = false`, `programs.firefox.enable` | `security.sudo.wheelNeedsPassword = false`, NOPASSWD reboot rule (in `desktop.nix`), `programs.firefox.enable`, the `kde-baloo` systemd drop-in pinning `QT_QPA_PLATFORM=offscreen` (the "Stop Baloo error message" change) | tumbler/gvfs, sudo reboot rule, `systemd.user.services.emacs.serviceConfig.TimeoutStartSec = "7min"`, `%HOST%` hostname |

`nixos/home-manager.nix` (115) → `modules/nixos/home-manager.nix` (137): the gtk/dunst/
screen-locker/udiskie blocks come along mostly verbatim; the `gpg-import-keys` systemd user
unit is dropped and replaced by `programs.git.commit.gpgsign = false` (with a comment about
the signing key only existing on the Mac; the shared module's default is `true`); polybar
config now comes from `modules/nixos/config/polybar/*.ini` via `pkgs.replaceVars`, and
`systemd.user.services.polybar.Install.WantedBy = lib.mkForce [ ];` stops the bar appearing
over Plasma/XFCE. `modules/nixos/files.nix` (368 lines) is new: bspwmrc, sxhkdrc, polybar
scripts and the rofi `.rasi` files, all written under `/home/${user}/.config` (the comment in
`DESKTOP.md` notes the old `builtins.getEnv "HOME"` variant wrote the wrong directory when
the switch ran as root).

`nixos/packages.nix` (47) → `modules/nixos/packages.nix` (58): same shape, minus
`yubikey-manager`/`yubioath-flutter`/`yubikey-agent`(kept) and the nerd-font set; plus
`keepassxc`, `pavucontrol`, `rofi`/`rofi-calc`, `libtool`, `flameshot`, `unixtools.ifconfig`/
`netstat`, `xclip`, `xwininfo`, `xrandr`, `inotify-tools`, `libnotify`, `pcmanfm`, `xdg-utils`,
`google-chrome`, `appimage-run`, `gnumake`, `cmake`, `home-manager`, `fontconfig`.

Two new docs describe this port: `modules/nixos/README.md` (layout, hosts, multi-host
recipe, bspwm hotkeys) and `modules/nixos/DESKTOP.md` (what was ported/dropped from the
starter desktop, the lightdm-vs-SDDM login story, the `backup`/`overwriteBackup` policy for
the GTK files Plasma also writes, and the template's rough edges).

`nixos/README.md` (the layout list) is deleted; its content now lives in
`modules/nixos/README.md`.

---

## 7. Darwin

| | `old` | `dev` |
| --- | --- | --- |
| host config | `darwin/default.nix` (143 lines) | `hosts/darwin/default.nix` (92 lines) |
| hostname | `networking.{hostName,computerName,localHostName} = "goyang"` | **not set at all** |
| imports | `./secrets.nix ./home-manager.nix ../shared ../shared/cachix` | `../../modules/darwin/{secrets,home-manager}.nix` in the restructure, reduced to `../../modules/darwin/home-manager.nix` + `../../modules/shared` after `9de1bcc` |
| `home-manager.backupFileExtension` | `"nix-darwin-backup"` | removed |
| Touch ID for sudo | `security.pam.services.sudo_local.touchIdAuth = true` | removed |
| nix package | `pkgs.nixVersions.latest`, `enable = true` | `pkgs.nix` |
| `extraOptions` | `nix-command flakes auto-allocate-uids` | `nix-command flakes` |
| substituters | from `shared/cachix` | inlined `substituters` + `trusted-public-keys` |
| emacs | — | `launchd.user.agents.emacs` (KeepAlive, `wait4path … emacs --fg-daemon`, logs to `/tmp/emacs.{err,out}.log`) and an `emacs-launcher.command` in home-manager |
| `system.stateVersion` | `4` | `5` |
| `system.defaults` | large set: `LaunchServices.LSQuarantine`, `menuExtraClock.Show24Hour`, `AppleShowScrollBars`, `AppleFontSmoothing`, `AppleKeyboardUIMode`, all the `NSAutomatic*` substitutions off, `NSNavPanelExpanded*`, `NSTextShowsControlCharacters`, `NSWindowResizeTime = 0.001`, `NSAutomaticWindowAnimationsEnabled = false`, `NSScrollAnimationEnabled = false`, `swipescrolldirection = false`, dock `autohide = true` + `autohide-delay`/`-time-modifier`, spring-loading, `launchanim = false`, `mineffect = "suck"`, `minimize-to-application`, `mouse-over-hilite-stack`, `mru-spaces = false`, `showhidden`, `show-process-indicators`, plus finder/trackpad entries | a much smaller template set: `AppleShowAllExtensions`, `ApplePressAndHoldEnabled = false`, `KeyRepeat = 2`, `InitialKeyRepeat = 15`, `mouse.tapBehavior`, `sound.beep.{volume,feedback}`, dock `{autohide=false, show-recents=false, launchanim=true, orientation="bottom", tilesize=48}`, `finder._FXShowPosixPathInTitle`, trackpad `{Clicking, TrackpadThreeFingerDrag}` |
| `darwin/home-manager.nix` (→ `modules/darwin/`) | `homebrew.onActivation = {autoUpdate, cleanup = "zap", upgrade}`, `taps = []`, `brews = []`, a `home.activation.gpgImportKeys` LaunchAgent plist that imported `~/.ssh/pgp_github.{key,pub}` | `onActivation` reduced to a commented `cleanup = "uninstall"`; the gpg-import LaunchAgent is gone; `masApps` kept; user module takes `user/gitName/gitEmail` via `extraSpecialArgs` |
| `darwin/secrets.nix` | live secrets: `syncthing-cert`/`syncthing-key` → `~/Library/Application Support/Syncthing/`, `github-ssh-key` → `~/.ssh/github` (symlink, group `staff`), `github-signing-key` | commented stub in the restructure; **file deleted in `9de1bcc`**, no darwin config declares an `age.secrets` any more |
| `darwin/packages.nix` | shared list + `dockutil` + `duti` | shared list + `dockutil` |
| `darwin/casks.nix` | ~130 lines, a personal list (firefox/librewolf/waterfox/floorp, amethyst, karabiner-elements, iTerm2, gpg-suite, bitwarden, `zsa-wally`, android-studio, blender, …) | template list: `homebrew/cask/docker`, `visual-studio-code`, `iterm2`, `postman`, `cursor`, `raycast`, `google-chrome` + commented examples |
| `darwin/dock/default.nix` | the same dock module | reformatted, with an added source-comment link to the upstream gist; `username` moved inside the `local.dock` submodule |
| `darwin/README.md` | the file | moved to `modules/darwin/README.md` and rewritten in this update with the current layout and the Intel-Mac status (§11.5) |

---

## 8. Docs and metadata

| file | `old` | `dev` |
| --- | --- | --- |
| `README.md` | determinate-nix install steps, `xcode-select`, `ssh -T git@github.com`, `bin/build`, and "update `flake.nix` by hand" | deleted in the restructure; a new short index (consumers, layout, deploy commands, flake-app caveat, doc index) was added in this update |
| `.gitignore` | `result`, `.DS_Store` | **deleted** (so `result` and `.DS_Store` are no longer ignored — §11.6) |
| `update-nixpkgs.sh` | present | deleted (§2.1) |
| `arch/README.md` | manual Arch setup steps (fonts, zsh in `/etc/shells`, gparted) | deleted with `arch/` |
| `nixos/README.md` | layout list | deleted → `modules/nixos/README.md` |
| `modules/shared/README.md` | — | in the restructure it still listed `cachix/`, which no longer existed; rewritten in this update (real layout, the impure emacs overlay and which host needs it) |
| `modules/nixos/README.md` | — | listed a `default.nix` and the stub `secrets.nix` that do not exist; the `specialArgs` recipe showed `{ inherit user; }` where the flake passes `gitName`/`gitEmail` too. Both fixed in this update |
| `modules/nixos/DESKTOP.md` | — | refreshed in this update: the emacs-overlay row, the verified `home.file` list, `gtk.gtk4.theme`/`gtk.css`, the `commit.gpgsign` override (the old text said commits fail without a signing key on NixOS — they no longer do), and the `matchBlocks` note |
| `hosts/nixos/mokpo/SECRETS.md` | — | its "the stub `modules/nixos/secrets.nix` still lists it" paragraph was corrected in `9de1bcc` |
| `secrets/README.md` | — | now states that no darwin host consumes a secret |
| `overlays/README.md` | present, unchanged | present, unchanged (plus a note on what is actually in the directory) |
| binary assets | none (text only) | `modules/nixos/config/login-wallpaper.png` (708 KB, 3000×2446) |

---

## 9. Files that exist in only one branch

Only in `old` (35 files, all shown as `D` in `git diff --name-status`):

```
.gitignore  README.md  update-nixpkgs.sh
arch/README.md  arch/config/test.txt  arch/default.nix  arch/files.nix  arch/packages.nix
bin/apply  bin/arch-build  bin/build  bin/darwin-build  bin/nixos-build
darwin/{casks,default,home-manager,secrets}.nix  darwin/dock/default.nix
nixos/{README,default,files,hardware-configuration,home-manager,packages,secrets}.nix
shared/{default,files,packages}.nix  shared/cachix/default.nix
shared/config/{amethyst.yml,emacs-profiles.el,quicklisp.lisp}
shared/config/emacs/{config.org,init.el,.gitignore}
```

Only in `dev` (51 files):

```
agenix-rules.nix  diff-branches-dev-old.md  README.md
apps/aarch64-linux (symlink → x86_64-linux)
apps/{aarch64-darwin,x86_64-darwin}/{apply,build,build-switch,clean}
apps/x86_64-linux/{apply,build-switch,clean}
hosts/darwin/default.nix  hosts/nixos/default.nix
hosts/nixos/mokpo/{default,hardware-configuration,secrets}.nix  hosts/nixos/mokpo/{README,SECRETS}.md
modules/darwin/{casks,home-manager}.nix  modules/darwin/dock/default.nix
modules/nixos/{README,DESKTOP}.md  modules/nixos/{desktop,disk-config,files,home-manager,packages}.nix
modules/nixos/config/login-wallpaper.png  modules/nixos/config/polybar/{bars,colors,config,modules,user_modules}.ini
modules/nixos/config/rofi/{colors,confirm,launcher,message,networkmenu,powermenu,styles}.rasi
modules/shared/{default,files,packages}.nix  modules/shared/config/emacs/init.el
overlays/10-feather-font.nix  secrets/{README.md,github-ssh-key.age}
```

The list is 51 because git counts `README.md` (re-added in this update) and
`diff-branches-dev-old.md` as additions; against `9de1bcc` alone it is 49.

---

## 10. Point-by-point deltas inside files that exist in both

* `overlays/` — `old` had an `overlays/` directory referenced by `shared/default.nix` and only a
  README in it; `dev` adds the first actual overlay, `10-feather-font.nix` (fetchzip from
  `dustinlyons/feather-font`). Polybar's `font1` and the rofi `.rasi` files use it.
* `shared/config/emacs/config.org` (1477 lines, 99% identical) — three edits only:
  `user-full-name`/`user-mail-address` back to `%NAME%`/`%EMAIL%` tokens, the macOS
  PATH/`exec-path` block back to `%USER%`, and one `:branch "master" → "main"`. The file
  itself was **deleted in `9de1bcc`**: nothing installed it, and `modules/shared/config/emacs/init.el`
  downloads the upstream copy from `raw.githubusercontent.com` when `~/.config/emacs/config.org`
  is absent.
* `shared/config/p10k.zsh` — unchanged; `modules/shared/home-manager.nix` is what now wires
  it in (`lib.cleanSource ./config`, file `p10k.zsh`).
* `modules/shared/config/emacs/init.el` — rewritten (86 → 234 lines): gains an
  `org-config-file`/`EMACS_CONFIG_ORG` indirection plus a `default-config-file`/`default-config-url`
  fallback pointing at `raw.githubusercontent.com/dustinlyons/nixos-config/9ad810c8…/shared/config/emacs/config.org`,
  `package-initialize` at startup, and messages on the archive checks.
* `flake.lock` — see §2.1.
* `hardware-configuration.nix` (`nixos/` → `hosts/nixos/mokpo/`) — different UUIDs throughout
  (root, LUKS, ESP), `usbhid` added to `availableKernelModules`, the trailing
  `networking.useDHCP = lib.mkDefault true` block removed.

---

## 11. Discrepancies noticed in `dev` (flagged, not touched)

1. **`apps/*/*` are mode 100644** while `bin/*` was 100755, and `mkApp` does
   `exec ${self}/apps/${system}/${scriptName}` — the exec fails with `Permission denied`
   (evidence in §5). Fix: `chmod +x apps/*/*` and re-commit, or invoke the scripts with `bash`.
2. **`apps/<system>/apply` still rewrites `flake.nix`** to insert a `secrets` input pointing
   at `git+ssh://git@github.com/%GITHUB_USER%/%GITHUB_SECRETS_REPO%.git`, i.e. the flow the
   `dev` branch removed in favour of in-repo `secrets/` + `agenix-rules.nix`. It also still
   advertises the upstream author's repo in its "star this repo" prompt.
3. **NixOS emacs daemon** — `old` enabled `services.emacs`; `mokpo` does not, while
   `~/.config/bspwm/bspwmrc` waits for the daemon in a loop (`DESKTOP.md` lists this).
4. **`mokpo` no longer manages `authorizedKeys`** for `atm`/`root`, which `old`'s
   `nixos/default.nix` did.
5. **The Intel Mac's user config no longer evaluates.** `x86_64-darwin` (the Mac `goyang`) fails
   with `error: Nixpkgs 26.11 has dropped support for x86_64-darwin`, raised from `nixpkgs_3`
   (`e158d9ed9b`). The system half still evaluates (`…config.system.stateVersion` → `5`, via the
   flake's own `nixpkgs` `f5c082a40f`), and `aarch64-darwin` is unaffected. Because
   `home-manager` no longer has `inputs.nixpkgs.follows = "nixpkgs"`, its nixpkgs is
   `nixpkgs_3`, i.e. the one that dropped the platform. Either restore the `follows` or pin
   the input to `nixpkgs-26.05-darwin`.
6. **No `.gitignore`** — `result` symlinks (from the build apps) and `.DS_Store` show up as
   untracked. The cleanup commit and this doc update both had to add files explicitly because
   of it.
7. **`modules/nixos/README.md`'s multi-host recipe** still points at the upstream `garfield`
   host as the worked example; there is no in-repo example beyond `mokpo` itself.

---

Reproduce any of the above with `git diff old dev -- <path>`; the full diff is also saved at
`/home/atm/.hermes/cache/scratch/old-dev.diff` (scratch, pruned after 72h).
