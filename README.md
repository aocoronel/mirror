# Declare installed programs in Arch Linux

`mirror` is a tool that allows you to declare what packages are installed in your system. It's highly inspired in [NixOS](https://nixos.org/) and [rebos](https://gitlab.com/oglo12/rebos), but it's main goals are to simply allow the user to declare the packages they want to install in their system using `pacman`.

To use this, you must read the [`Setup`](#setup) section to properly understand how to use it. Use with caution!

This script will use `pacman -Qqe` to compare the system packages to your configuration, which means only programs explicitly installed by the user, thus does not include dependencies. You will mostly want to add all your system packages first, so the script does not try to remove important programs from your system such as `grub`, `base` and `base-devel`.

Differently than [rebos](https://gitlab.com/oglo12/rebos) there is no setup step, which would safely register all your currently installed programs, so you can calmly build your rebos configuration file. If you run this tool without a configuration file it will prompt you to uninstall all everything from your machine. This is a design choice.

You decide exactly what programs to be installed: If your configuration does not have `grub`, so it shouldn't be installed.

## Features

- Install and remove pacman packages
- Install and remove AUR packages

## Installation

```bash
git clone https://github.com/aocoronel/mirror
cd mirror
mv src/mirror $HOME/.local/bin
mv src/mirror-organizer $HOME/.local/bin
chmod +x "$HOME/.local/bin/mirror" "$HOME/.local/bin/mirror-organizer"
```

## Usage

```
Declare installed programs in Arch Linux

Usage:
  mirror FLAG <FLAG_INPUT>
  mirror -h |  help

Flags:
  -h, --help                 Displays this message and exits

Example:
  mirror -p artix
```

### Configuration

**Currently there is support for:** Pacman packages and AUR packages.

The configuration directory is at `$HOME/.local/share/mirror/`, and usually you will use a profile subdirectory called `profile/`. In this subdirectory will be your configuration files, that will actually reflect on your machine. You can use symlinks, directories and even split configuration files as you which.

There are three environment variables available:

- `mirror` envs:
  - The default directory for your config managed by `MIRROR_DIR`, default to `$HOME/.local/share/mirror/`
- `mirror-organizer` envs:
  - `MIRROR_DIR` and `MIRROR_PROFILE`
  - To give a changelog of what programs were added and which were removed, a file is set in `MIRROR_LOG`, default to `$HOME/.local/state/mirror_state`
  - If you don't want to store your config at `$MIRROR_DIR` you can set a subdirectory to it, by using the `MIRROR_PACKAGE_DIR` env, default to `$MIRROR_DIR/packages`

**The configuration files use the following extensions:** Pacman packages end with `.pacman`, thus AUR packages end with `.aur`.

#### Setup

To get started, you can add all your installed packages to a starting configuration file:

```bash
# Add all your system packages to a configuration file that were
# explicitly installed by the user
pacman -Qqe > "$HOME/.local/share/mirror/profile/packages.pacman"
```

If you have AUR packages installed, you can split pacman packages from AUR ones. This one is a bit more elaborated:

```bash
sudo pacman -S $(pacman -Qqe) 2>&1 | rg "error:" | awk '{print $5}' > "$HOME/.local/share/mirror/profile/packages.aur"
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

#### Managing your configuration

For a production example, look at my own configuration at [aocoronel/mirror-config](https://codeberg.org/aocoronel/mirror-config).

The configuration files should be like the generated files like above. Just plain text and the name of the package.

Here are some examples of configuration files. By default, all empty lines and commented lines with `#` are omitted. Note that the file is within the `software` subdirectory.

```
# $HOME/.local/share/mirror/profile/software/browser.pacman

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

The same applies for AUR packages. They must be ending with the proper extension.

```
# $HOME/.local/share/mirror/profile/software/browser.aur
# librewolf
# ungoogled-chromium
zen-browser-bin
```

In the example above, only lynx (pacman) and zen-browser-bin (AUR) will be installed.

Ultimately, `mirror` allow you to customize the configuration structure the way you want, however if you ever considered having different profiles for different machines and other little tweaks, I made an extra tool called `mirror-organizer` to help with it.

##### Organizing your configuration

The `mirror-organizer` is a tool that generates symlinks from your configuration files in the `packages/` subdirectory to the profile subdirectory. You can use it by moving your configuration files to a `packages/` and running `mirror-organizer`. All your configuration files will me symlinked to `profile/`.

To leverage the power of this tool, you can also use a `-i` or `--ignore-file` to ignore the configuration files you don't want to be present in your set profile. This way you can have two ignore files for a X device running Intel and Y device running AMD, for example, and only install the necessary drivers. By default, the ignore files is `.mignore`.

By this way, you can have as many ignore files as you want for different machines, without having to write copies of your already existing configuration files.

## License

This repository is licensed under the MIT License, allowing for extensive use, modification, copying, and distribution.
