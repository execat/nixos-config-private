# Secrets for this host, decrypted by agenix at activation.
#
# Identity: nothing extra to keep. Decryption uses this host's own OpenSSH host keys — the same
# keys agenix defaults to on NixOS (`services.openssh.hostKeys`, filtered to rsa/ed25519), set
# explicitly below. Everything in `../../../secrets/*.age` is encrypted to their public keys (the
# recipient list lives in `../../../agenix-rules.nix`), so activation decrypts as root and there
# is no separate age key to generate, copy between machines or lose.
#
# The trade-off: reinstalling this machine generates new host keys, so before wiping it, add the
# new public key to `agenix-rules.nix` and re-encrypt with `agenix -r`. Adding a key you hold
# off-machine (the Mac's, say) as a second recipient avoids that chore. Workflow:
# `../../../secrets/README.md`.
{ config, user, ... }:

{
  age.identityPaths = [
    "/etc/ssh/ssh_host_ed25519_key"
    "/etc/ssh/ssh_host_rsa_key"
  ];

  age.secrets."github-ssh-key" = {
    file = ../../../secrets/github-ssh-key.age;

    # Not the usual /run/agenix symlink: decrypt straight to the path the ssh settings expect.
    # `programs.ssh.settings."github.com".IdentityFile` in modules/shared/home-manager.nix points
    # at /home/${user}/.ssh/id_github, which nothing ever created — the key this machine was
    # installed with sits at ~/.ssh/github, so ssh to github.com failed with
    # "no such identity: /home/atm/.ssh/id_github: No such file or directory".
    path = "/home/${user}/.ssh/id_github";
    mode = "600";
    owner = user;
    group = "users";
    symlink = false;
  };
}
