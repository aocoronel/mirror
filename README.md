# A better way to manage packages

`mirror` is a tool that allows you to declare what packages are installed in your system.

It's highly inspired in NixOS and [rebos](https://gitlab.com/oglo12/rebos), but it's main goals are to simply allow the user to declare the packages they want to install in their system using the default package manager.

Note: Currently this script does only work for Arch Linux based distros.

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

## License

This repository is licensed under the MIT License, allowing for extensive use, modification, copying, and distribution.
