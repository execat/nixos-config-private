# secrets

`age`-encrypted files, committed here and decrypted at activation on the machine that owns them.
The recipient lists live in `../agenix-rules.nix` (what the agenix CLI reads); which host decrypts
what, and where the plaintext lands, is in that host's `secrets.nix`.

| file | decrypted to | recipients | wired up in |
| --- | --- | --- | --- |
| `github-ssh-key.age` | `/home/atm/.ssh/id_github` | mokpo's SSH host keys | `hosts/nixos/mokpo/secrets.nix` |

No macOS host consumes anything here: neither darwin configuration declares an `age.secrets`
(the template's stub `modules/darwin/secrets.nix` was removed), so this directory and
`agenix-rules.nix` are mokpo-only today.

## The identity is the host key

On NixOS, agenix decrypts with the host's own OpenSSH host keys unless told otherwise, and
`hosts/nixos/mokpo/secrets.nix` pins exactly that:

    /etc/ssh/ssh_host_ed25519_key
    /etc/ssh/ssh_host_rsa_key

Nothing has to be generated, copied onto the machine or kept in a password manager. The price:
a reinstall generates new host keys, and the files here stop decrypting. Two ways out — add the
new public key to `agenix-rules.nix` and `agenix -r` before wiping, or put a key you hold
off-machine (the Mac's `~/.ssh/id_ed25519.pub` is the obvious one) in the recipient list now so
the set survives reinstalls.

## Workflow

```sh
# every .age file here is encrypted to exactly the recipients in agenix-rules.nix?
agenix -c

# edit one: decrypts with the host key (hence root), $EDITOR, re-encrypts to the rules
sudo agenix -i /etc/ssh/ssh_host_ed25519_key -e secrets/github-ssh-key.age

# replace contents without an editor (piped input is not decrypted first)
printf 'new contents\n' | sudo agenix -i /etc/ssh/ssh_host_ed25519_key -e secrets/foo.age

# after a recipient list changes
sudo agenix -r

# deploy
sudo nixos-rebuild switch --flake .#mokpo
```

Run these from the repo root: agenix finds `agenix-rules.nix` in the current directory (or a
parent) and resolves the paths in it relative to that file.

## Adding one

1. Encrypt it — recipients only, so this needs no private key and no sudo:
   `age -R "$(cat /etc/ssh/ssh_host_ed25519_key.pub)" -o secrets/foo.age /path/to/plaintext`
2. Add `"secrets/foo.age".publicKeys = mokpo;` to `agenix-rules.nix`.
3. Add it to the host's `secrets.nix`:

   ```nix
   age.secrets.foo = {
     file = ../../../secrets/foo.age;
     path = "/where/it/should/land";   # default: /run/agenix/foo, symlinked into place
     mode = "600";
     owner = "atm";
   };
   ```

4. `git add secrets/foo.age` and commit. **A flake only sees tracked files**, so an untracked
   `.age` fails the build with a missing path rather than at activation.

The `.age` files are safe to commit and to push: they hold no plaintext and no key material.
