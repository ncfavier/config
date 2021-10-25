# ❄️ ≃ 💙

This repository defines almost<sup id=top-almost>[†](#almost)</sup> all of the
configuration for my machines running the [NixOS](https://nixos.org/) Linux
distribution, including installed programs, configuration files and running
services, in a declarative and reproducible way.

NixOS is built on top of [Nix](https://nixos.org/manual/nix/stable/#chap-introduction),
a package manager and build system with a declarative approach based on a
[lazy](https://en.wikipedia.org/wiki/Lazy_evaluation)
[functional programming](https://en.wikipedia.org/wiki/Functional_programming)
language. It makes life infinitely easier. (See [GNU Guix](https://guix.gnu.org/)
for an alternative with a stronger focus on software freedoms.)

This repository is not meant to be used as-is by anyone else, but feel free to take
inspiration (see the [license](https://github.com/ncfavier/config/blob/main/LICENSE)).
Of course, this is a perpetual work in progress.

## Structure

#### [`modules`](https://github.com/ncfavier/config/tree/main/modules) is where most of the configuration is defined.

The top-level modules are imported for every machine and may then define their
own conditions; for example, the [`server`](https://github.com/ncfavier/config/blob/main/modules/server/default.nix)
module imports every module in the `server` directory if the current machine is
a server. Similarly, the [`station`](https://github.com/ncfavier/config/blob/main/modules/station/default.nix)
module groups modules to be used in physical machines (desktops and laptops).

Configuration for my home directory is managed using [Home Manager](https://github.com/nix-community/home-manager)
(see the [`home-manager`](https://github.com/ncfavier/config/blob/main/modules/home-manager.nix) module).

Configuration for Nix itself is defined in the [`nix`](https://github.com/ncfavier/config/blob/main/modules/nix.nix) module.
This module defines the file `~/.nix-defexpr/default.nix`, which is used as the
source of Nix expressions for the `nix-env` and `nix repl` commands. This file
tries to replicate the environment available in modules:
`lib`, `config`, `pkgs`, etc.

#### [`machines`](https://github.com/ncfavier/config/tree/main/machines) contains machine-specific configuration:

- [`wo`](https://github.com/ncfavier/config/blob/main/machines/wo.nix) is a
  Netcup VPS that runs web, mail and DNS servers for [`monade.li`](https://monade.li),
  serves as an IRC bouncer (see the [`weechat`](https://github.com/ncfavier/config/blob/main/modules/server/weechat/default.nix) module)
  and a central node for my WireGuard network and for Syncthing.
- [`mo`](https://github.com/ncfavier/config/blob/main/machines/mo.nix) is my
  laptop, a Lenovo ThinkPad T420.
- [`fu`](https://github.com/ncfavier/config/blob/main/machines/fu.nix) is my
  desktop computer.

#### [`secrets`](https://github.com/ncfavier/config/tree/main/secrets) contains [sops](https://github.com/mozilla/sops)-encrypted secrets.

They are decrypted on system activation by [sops-nix](https://github.com/Mic92/sops-nix)
using my GPG private key (see the [`secrets`](https://github.com/ncfavier/config/blob/main/modules/secrets.nix) module).

#### [`lib`](https://github.com/ncfavier/config/blob/main/lib/default.nix) extends the Nixpkgs lib.

In particular, [`lib.my`](https://github.com/ncfavier/config/blob/main/lib/my.nix) is a collection
of variables used in all the modules, such as my username, domain name and
email addresses.

`my.machines` contains basic information about all my machines (including those
not <small>yet</small> running NixOS) such as WireGuard public keys and Syncthing IDs.
The module argument `here` is mapped to `my.machines.${hostname}`.

This attribute uses the Nixpkgs module system to define default values.

#### [`flake.nix`](https://github.com/ncfavier/config/blob/main/flake.nix) declares this repository as a [flake](https://github.com/tweag/rfcs/blob/flakes/rfcs/0049-flakes.md), an experimental feature of Nix.

This is the entry point where things are plugged into each other. The flake
exports the following outputs:
- `lib` is the lib defined above.
- `nixosModules` is the set of top-level modules imported in each configuration.
- `nixosConfigurations` is the set of configurations for my machines.
- `packages.x86_64-linux.iso` creates an ISO image similar to the official
  unstable minimal ISO but with a few conveniences, like my localisation settings,
  a flakes-enabled Nix, git, and the GPG agent with SSH support
  (see [`iso.nix`](https://github.com/ncfavier/config/blob/main/iso.nix)).

## Usage

The [`meta`](https://github.com/ncfavier/config/blob/main/modules/meta.nix)
module defines a `config` command which I use to manage my systems. It has the
following subcommands:

- `repl` runs `nix repl ~/.nix-defexpr`.
- `compare` allows me to compare the locked version of an input to the current upstream version.
- `update` runs `nix flake update` on this flake.
- `revert` is meant to be used after `config test` to revert to the latest generation.
- `home` builds and activates my Home Manager configuration without building the whole
  system. This is useful for quickly testing a change to my home.
- `env` is meant to be *sourced* (as in `. config env`) by Bash scripts and exports
  a few common variables using `lib.toBash`.
- every other command (`switch`, `test`, `build`, …) is passed on to `nixos-rebuild`.
  If prefixed with `@host`, the command will be run remotely on `host`.

---------------

<sup id=almost>[†](#top-almost)</sup> things currently not managed by this
repository include:
- partition layouts, disk encryption
- GPG keys (used to decrypt secrets)
- `wpa_supplicant` configuration
- general state (mail, Firefox and Thunderbird profiles, command histories, …)
