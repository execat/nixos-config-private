# Secrets on mokpo

Two things live in this file: what is wired **today** (working, verified) and the plan to move the
encrypted blobs to the separate `github.com/execat/nix-secrets` repo (**not done yet** — every step
in that half is a plan, not a description of the machine).

The CLI workflow itself (encrypt / check / edit / rekey) is in `secrets/README.md` at the repo root
and is not repeated here; this file carries the host-specific decisions.

## What is wired today

`secrets.nix` in this directory imports agenix and pins the identity explicitly:

| | |
| --- | --- |
| module | `hosts/nixos/mokpo/secrets.nix`, imported from `default.nix` together with `inputs.agenix.nixosModules.default` |
| identity | this host's own OpenSSH host keys — `/etc/ssh/ssh_host_ed25519_key`, `/etc/ssh/ssh_host_rsa_key` |
| recipients | `agenix-rules.nix` at the repo root, same two public keys |
| blobs | `secrets/*.age` at the repo root (currently only `github-ssh-key.age`) |
| CLI | `age` + `agenix` in `environment.systemPackages` (activation needs neither) |

Nothing has to be generated for this to work: the host keys exist from the install, agenix's NixOS
default is the same list, and decryption happens as root at activation, so there is no private age
key to create, copy between machines or lose. Host key fingerprints for reference:

    ed25519  SHA256:x78m8/qAn2kPfKnYlqFufOV8ggfCBR3tW+NvbGn/f9k
    rsa      SHA256:SMQkFJ77NyC8id5bHftodoVqgnkKgREUC4b2Fb2S5/w

One secret is deployed: `github-ssh-key` → `/home/atm/.ssh/id_github` (`0600`, `atm:users`,
`symlink = false`). That path is not arbitrary — `programs.ssh.settings."github.com".IdentityFile`
in `modules/shared/home-manager.nix` already pointed `IdentityFile` at it while nothing ever created
the file, so `ssh -T git@github.com` failed with `no such identity: /home/atm/.ssh/id_github` →
`Permission denied (publickey)`. The key the machine was installed with sat at `~/.ssh/github`;
after this secret is deployed, `ssh -T git@github.com` answers `Hi execat!` (`~/.ssh/github` is left
in place, now an unmanaged duplicate).

## Why a separate repo

Not for secrecy — the `.age` files are ciphertext and safe to publish; the recipients and file names
are all a reader learns. It is for rotation and for the second machine: `agenix -e`, `-r` and the
recipient list move independently of this config repo's history, and a new host only has to be added
to `agenix-rules.nix` instead of to both repos.

## Status of `github.com/execat/nix-secrets`

    git ls-remote git@github.com:execat/nix-secrets.git
    f8678ef0a59392c8ac1a1a1439a3c936aab2ff9d  HEAD
    f8678ef0a59392c8ac1a1a1439a3c936aab2ff9d  refs/heads/dev

Private, default branch `dev`, one commit (`Initial commit`) containing nothing but a 13-byte
`README.md`. `atm` can read it (the API/HTTPS route asks for credentials, SSH works because the
GitHub key is now deployed). **Root cannot** — see below.

### The blocker: `sudo nixos-rebuild` fetches flake inputs as root

Verified on this machine:

    sudo nix flake metadata --no-write-lock-file 'git+ssh://git@github.com/execat/nix-secrets.git?ref=dev'
    error: Failed to fetch git repository 'ssh://git@github.com/execat/nix-secrets.git'

`/root/.ssh` does not exist and `/etc/ssh/ssh_known_hosts` is empty, so root cannot verify GitHub's
host key, let alone authenticate. The same command as `atm` succeeds. Three ways out:

| approach | root fetches on its own | cost | failure mode |
| --- | --- | --- | --- |
| read-only deploy key for root (recommended) | yes | one keypair, ~8 lines of config, one click in GitHub | deploy key leak = read access to ciphertext only |
| fetch as yourself, then switch | no | `nix flake update secrets` before every switch | bare `sudo nixos-rebuild switch` fails with the fetch error above once the store copy is gone (it is not permanently gcrooted) |
| leave the blobs in this repo | n/a | none | remains "not the nix-secrets repo" |

### The edits (all in this repo)

1. `flake.nix` — the input is named `secrets` because the starter modules already take a `secrets`
   argument, and `mokpoSystem` passes `inputs` as `specialArgs`:

   ```nix
   inputs.secrets = {
     url = "git+ssh://git@github.com/execat/nix-secrets.git?ref=dev";
     flake = false;
   };
   ```

2. `hosts/nixos/mokpo/secrets.nix` — point the one secret at it:

   ```nix
   file = "${secrets}/github-ssh-key.age";   # `secrets` via the module args
   ```

   Verified form: with the input fetched, this evaluates to
   `/nix/store/<hash>-source/github-ssh-key.age` as `atm` *and* as root.

3. `hosts/nixos/mokpo/secrets.nix` (or `desktop.nix`) — the fetch credential for root. The private
   half is delivered by *this* repo's agenix (which needs no fetching, so there is no circularity):

   ```nix
   age.secrets."nix-secrets-deploy-key" = {
     file = ../../../secrets/nix-secrets-deploy-key.age;
     path = "/root/.ssh/nix-secrets-deploy";
     mode = "600";
     owner = "0";
     group = "0";
     symlink = false;
   };
   ```

   and GitHub's host key plus a root-scoped identity rule, so `atm`'s own SSH stays untouched:

   ```nix
   programs.ssh = {
     knownHosts."github.com".publicKey =
       "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
     extraConfig = ''
       Match user root host github.com
         IdentityFile /root/.ssh/nix-secrets-deploy
         IdentitiesOnly yes
     '';
   };
   ```

   `programs.ssh.knownHosts` writes the *global* `/etc/ssh/ssh_known_hosts` (nixpkgs does it through
   `environment.etc`), which is what root reads. The key above is GitHub's ed25519 host key,
   `SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU` — cross-checked against both this machine's
   `known_hosts` and a live `ssh-keyscan github.com` (all three key types matched; the RSA key is
   `SHA256:uNiVztksCsDhcc0u9e8BujQXVUpKZIDTMczCvj3tD2s`).

   Shortcut: name the key `/root/.ssh/id_ed25519` and ssh picks it up with no `extraConfig` at all.
   The explicit path is preferred because it says what the key is for.

4. Where things end up afterwards: `agenix-rules.nix` and `secrets/*.age` move to the nix-secrets
   repo; this repo keeps `secrets/` for exactly one file — the bootstrap deploy key, which can never
   live in the repo it is used to fetch.

### Keys to produce

| key | needed for | private half | public half |
| --- | --- | --- | --- |
| mokpo's SSH host keys | decrypting every secret at activation (works today) | `/etc/ssh/ssh_host_*_key` | recipients in `agenix-rules.nix` |
| read-only deploy key (ed25519) | letting root fetch the private repo during a plain `sudo nixos-rebuild switch` | this repo → agenix → `/root/.ssh/nix-secrets-deploy` | nix-secrets → Settings → Deploy keys (leave write access **off**) |
| recovery age identity | decrypting / rotating after this laptop dies — the stand-in for keys on another machine | offline: paper, USB stick or password manager, **not** on mokpo | recipients in `agenix-rules.nix` for every secret |

Do **not** produce the template's per-user `~/.ssh/id_ed25519`. That is what `create-keys` /
`copy-keys` / `check-keys` in the starter repo were for (the stub `modules/nixos/secrets.nix` still
lists it as `age.identityPaths`), and it is exactly the key you would then have to copy between
machines and keep backed up. This host decrypts with its own host keys, so there is nothing to
create, copy or lose. Those three apps are declared in `flake.nix` with no scripts behind them —
ignore them until something needs a *user*-owned identity.

The recovery identity matters more than it looks: with only the two host keys as recipients, a dead
laptop means the ciphertext is unrecoverable. `/etc/ssh/ssh_host_*` are not backed up anywhere.

### Order of operations

1. Populate `execat/nix-secrets`: `agenix-rules.nix` (the same rules file, which the CLI discovers
   from the working directory, so `agenix -e` is run inside a checkout of *that* repo from then on),
   `secrets/github-ssh-key.age` moved over from this repo, a README, and push to `dev`.
2. Make the three config edits above.
3. Generate the deploy key and register the public half:

   ```sh
   ssh-keygen -t ed25519 -N '' -C 'mokpo root fetch: execat/nix-secrets (read-only)' \
     -f ~/.ssh/nix-secrets-deploy
   age -R /etc/ssh/ssh_host_ed25519_key.pub -R /etc/ssh/ssh_host_rsa_key.pub \
     -o secrets/nix-secrets-deploy-key.age ~/.ssh/nix-secrets-deploy
   ```

   plus `"secrets/nix-secrets-deploy-key.age".publicKeys = mokpo;` in `agenix-rules.nix`.
4. First switch, which is the one that cannot be fetched as root yet (the deploy key arrives *from*
   a switch) — so fetch as yourself, then switch; root then reuses the store copy:

   ```sh
   nix flake update secrets
   sudo nixos-rebuild switch --flake .#mokpo
   ```

5. Confirm root can fetch on its own afterwards:

   ```sh
   sudo nix flake metadata --refresh --no-write-lock-file \
     'git+ssh://git@github.com/execat/nix-secrets.git?ref=dev'
   ```

6. Edit loop from then on:

   ```sh
   cd ~/_code/nix-secrets && sudo agenix -i /etc/ssh/ssh_host_ed25519_key -e secrets/foo.age
   git commit -am '...' && git push
   cd ~/_code/nixos-config && nix flake update secrets && sudo nixos-rebuild switch --flake .#mokpo
   ```

### Still to decide

* Where the recovery identity lives — this box has no YubiKey attached and no `op`/`bw` CLI, so it
  has to be somewhere off mokpo.
* Register the deploy key by hand in GitHub, or `gh auth login` first (`gh` is installed but not
  logged in) to add it with `gh repo deploy-key add`.
* Keep the deploy-key secret in this repo's agenix (recommended: survives reinstalls, as long as the
  new host key is added as a recipient) or copy it to `/root/.ssh` by hand once.
* Once the rules file moves, `secrets/README.md` describes a file that is no longer here — it needs
  the same treatment (workflow for the secrets repo, bootstrap note for this one).

### Evidence collected on this machine

* `sudo nix flake metadata … git+ssh://…nix-secrets.git?ref=dev` → `Failed to fetch git repository`.
  As `atm`: resolves to `f8678ef0a59392c8ac1a1a1439a3c936aab2ff9d`.
* `/root/.ssh` absent; `sudo ssh -T git@github.com` → `Host key verification failed` (empty
  `/etc/ssh/ssh_known_hosts`); with atm's key it answers `Hi execat!`.
* With the input already in the store, root's `nix eval` resolves it without a fetch, and survives
  `--refresh` for a rev-pinned input; `nix-store --query --roots` shows only temporary roots, so the
  copy is collectable — which is why the bare-switch path is the fragile one.
* `"${secrets}/github-ssh-key.age"` from a `flake = false` input evaluates for both users.
* `ssh-keyscan github.com` and this machine's `known_hosts` agree on all three GitHub host keys.
