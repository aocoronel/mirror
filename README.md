# A better way to manage packages in Arch Linux

`mirror` is a tool that allows you to declare what packages are installed in your system.

It's highly inspired in NixOS and [rebos](https://gitlab.com/oglo12/rebos), but it's main goals are to simply allow the user to declare the packages they want to install in their system using the default package manager.

To use this, you must read the [`Setup`](#setup) section to properly understand how to use it. Use with caution!

This script will use `pacman -Qqe` to compare the system packages to your configuration, which means only programs explicitly installed by the user, thus not include dependencies. You will mostly want to add all your system packages at first, so the script does not try to remove important programs from your system such as `grub`.

Differently than [rebos](https://gitlab.com/oglo12/rebos) there is no setup step, which would safely register all your currently installed programs, so you can calmly build your rebos configuration file. If you run this tool without a configuration file it will prompt you to uninstall all applications from your machine. That's why you decide exactly what programs to be installed, and this tool will respect your config.

## Features

- Install and remove pacman packages
- Install and remove AUR packages

## Installation

```bash
git clone https://codeberg.org/aocoronel/mirror
cd mirror && mv src/mirror $HOME/.local/bin
chmod +x $HOME/.local/bin/mirror
```

## Usage

```
Reflect packages in a configuration file to system packages

Usage:
  mirror FLAG <FLAG_INPUT>
  mirror -h |  help

Flags:
-h              Displays this message and exits
--help          Displays this message and exits
-p <PROFILE>    Use profile

Example:
  mirror -p artix
```

### Configuration

**Currently there is support for:** Pacman packages and AUR packages.

The configuration directory is at `$HOME/.local/share/mirror/`, and usually you will use a profile which will be at the `profiles/` subdirectory. In this directory will be your configuration files, you can use symlinks, directories and even split configuration files as you which.

Pacman packages end with `.pacman`, thus AUR packages end with `.aur`.

#### Setup

To get started, you can add all your installed packages to a starting configuration file:

```bash
# Add all your system packages to a configuration file that were
# explicitly installed by the user
pacman -Qqe > "$HOME/.local/share/mirror/profiles/YOURPROFILE/packages.pacman"
```

If you have AUR packages installed, you can split pacman packages from AUR ones. This one is a bit more elaborated:

``` bash
sudo pacman -S $(pacman -Qqe) 2>&1 | rg "error:" | awk '{print $5}' > "$HOME/.local/share/mirror/profiles/YOURPROFILE/packages.aur"
# Explanation:
# 'sudo pacman -S $(pacman -Qqe)' will try to install all packages and will fail
# '2>&1' will redirect the error so it can be manipulated
# 'rg "error:"' will look for all lines containing error. Can be replaced with grep
# 'awk "{print $5}' will print the fifth column which are the AUR packages
comm -23 packages.pacman packages.aur > packages1.pacman && mv -f packages1.pacman packages.pacman
# Explanation:
# `comm -23 *.pacman *.aur` will compare both files returning only pacman packages
# `mv -f packages1 packages` will replace the old packages file
```

After that, it should be safe to start using `mirror` without the risk to compromise important programs.

#### Managing your config

The configuration files should be like the generated files like above. Just plain text and the name of the package.

Here are some examples of configuration files. By default, all empty lines and commented lines with `#` are omitted. Note that the file is within the `software` subdirectory of the `artix` profile.

```
# $HOME/.local/share/mirror/profiles/artix/software/browser.pacman

# brave
# ddgr
# firefox
# floorp
lynx
# nyxt
# qutebrowser
# vivaldi
# w3m
```

The same applies for AUR packages. They must be ending with the proper extension, or AUR packages are going to be parsed to `sudo pacman -S`.

```
# $HOME/.local/share/mirror/profiles/artix/software/browser.aur
# librewolf
# ungoogled-chromium
zen-browser-bin
```

## License

This repository is licensed under the MIT License, allowing for extensive use, modification, copying, and distribution.
