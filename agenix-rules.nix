# Recipients for every age file in ./secrets/, read by the agenix CLI (`agenix -e`, `-r`, `-c`).
#
# These are mokpo's own OpenSSH host keys. Activation decrypts with their private halves —
# hosts/nixos/mokpo/secrets.nix sets age.identityPaths to /etc/ssh/ssh_host_{ed25519,rsa}_key —
# so there is no separate age key to create, back up or lose. An attr name is the path of the
# encrypted file relative to this file.
#
# Reinstall = new host keys = these recipients stop matching. Before wiping the machine, put the
# new host key here and run `agenix -r`; adding a key you hold off-machine (e.g. the Mac's
# ~/.ssh/id_ed25519.pub) as a second recipient makes that a one-time job. See secrets/README.md.
let
  mokpo = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFpROYgSf4WriROg2NwsvjajdM1gXwOKB0DHBhBd5UkA root@nixos"   # /etc/ssh/ssh_host_ed25519_key.pub
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC6iIbD0BuwrjvhIx0ArkaTLT88DoKPWx7IVllWI84ZVu5jZlK/7GWDs1wA/cXAV6Bjxo9M8pSFsyIamtAdPfJhgTuRTTkL59uPKB3ovi5USM7JrqLwmvrL579zwZ8SOz3TrFFLcighNfuvWGdsnV+6b0I4XZVQ7tcZ6xNeVG8fQj3cPtcmVtKTz0D//t3XupzGlH2IWfNyd/Rph/UCfv3TNTnrRv4WkounlAHhBbJUdtMfYK8uFohCRO+0uo8fXTnFkpf6uwhrc92LTRYk5CYnsbuBxKb9BfyjtPOX36hNtAqBUSqumGwV3T9JLlOfpM609awwzP6w7iTBA7rj1aUWonZXcc8/vZH//rqHTddClhX2vFiDL/5A+Fw0IcL3I7oDMXN/k3o2hsftVXQf2B/ixdlZ3mI1V2lgRz7x0pKDkEoF9W++GwXqMyB11nkZeUVR/J2Xtk6BtWF21YqsNO6zBHQvIPitwlT5Kvho5Ahd2yheExRnMHGzWtH06fwlwHYY+0mL1f2zfRZJ96FFFPjMXumJ7WD7BsTFMrvJZpv5x79lC3ExtvHKZUv6zNZnWrZkQouDLP7/NN1EKrVFc/3zrG8wqWEBTYx3qpZXDC8550N4egVexYfowF/5nDywMBVk2qXdj323LhCXXqeDV5RTp+FHJNDts7+BDXC3bo3Prw== root@nixos"   # /etc/ssh/ssh_host_rsa_key.pub
  ];
in
{
  # GitHub SSH key: deployed to /home/atm/.ssh/id_github, the path the ssh settings already
  # point IdentityFile at. Managed by hosts/nixos/mokpo/secrets.nix.
  "secrets/github-ssh-key.age".publicKeys = mokpo;
}
