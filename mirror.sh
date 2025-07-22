#!/usr/bin/env bash

TMP_SYSTEM_PACMAN_PACKAGES=$(mktemp /tmp/pacman_pkgs_XXX)
TMP_SYSTEM_AUR_PACKAGES=$(mktemp /tmp/aur_pkgs_XXX)
TMP_PACMAN_CONFIG=$(mktemp /tmp/pacman_pkgs_config_XXX)
TMP_AUR_CONFIG=$(mktemp /tmp/aur_pkgs_config_XXX)

MIRROR_DIR=$HOME/.local/share/mirror/

trap cleanup RETURN EXIT

function cleanup() {
  rm "$TMP_SYSTEM_PACMAN_PACKAGES" "$TMP_SYSTEM_AUR_PACKAGES" "$TMP_PACMAN_CONFIG" "$TMP_AUR_CONFIG" &>/dev/null
}

function _filter_aur_programs() {
  local tmp_file
  tmp_file=$(mktemp /tmp/pacman_tmp_XXX)
  pacman -Qqe >"$tmp_file"
  # shellcheck disable=SC2024
  sudo pacman -S - <"$tmp_file" 2>&1 | sort -u | rg "error:" | awk '{print $5}' >"$TMP_SYSTEM_AUR_PACKAGES"
  comm -23 "$tmp_file" "$TMP_SYSTEM_AUR_PACKAGES" >"$TMP_SYSTEM_PACMAN_PACKAGES"
  rm "$tmp_file"
}

function _read_config() {
  local pacman_files tmp_file
  local package=$1 # pacman, aur, flatpak
  tmp_file=$(mktemp /tmp/pacman_tmp_XXX)

  [[ ! -d "$MIRROR_DIR/$package" ]] && mkdir -p "$MIRROR_DIR/$package"
  [[ ! -d "$MIRROR_DIR/profiles/$MIRROR_PROFILE/$package" ]] && mkdir -p "$MIRROR_DIR/profiles/$MIRROR_PROFILE/$package"

  mapfile -t pacman_files < <(find -L "$MIRROR_DIR/profiles/$MIRROR_PROFILE/$package" -type f -iname "*.$package")

  if [[ ${#pacman_files[@]} -eq 0 ]]; then
    return 1
  fi

  cat "${pacman_files[@]}" |
    sed 's/^[[:space:]]*//;s/[[:space:]]*$//' |
    grep -v '^$' |
    sort -u >"$tmp_file"

  if [ "$package" == "pacman" ]; then
    mv "$tmp_file" "$TMP_PACMAN_CONFIG"
  elif [ "$package" == "aur" ]; then
    mv "$tmp_file" "$TMP_AUR_CONFIG"
  fi

  return 0
}

function _install_pacman() {
  local pkgs
  pkgs=$(comm -23 "$TMP_PACMAN_CONFIG" "$TMP_SYSTEM_PACMAN_PACKAGES")
  echo -e "Installing pacman packages"
  if [[ -n "$pkgs" ]]; then
    # shellcheck disable=SC2086
    sudo pacman -S --needed $pkgs || true
  else
    echo " there is nothing to do"
  fi
}

function _remove_packages() {
  local pkgs tmp_file
  local comm=$1
  local package=$2
  tmp_file=$(mktemp /tmp/pacman_tmp_XXX)

  if [ "$package" == "AUR" ]; then
    pkgs=$(comm "-$comm" "$TMP_AUR_CONFIG" "$TMP_SYSTEM_AUR_PACKAGES")
  elif [ "$package" == "pacman" ]; then
    comm "-$comm" "$TMP_PACMAN_CONFIG" "$TMP_SYSTEM_PACMAN_PACKAGES" >"$tmp_file"
    pkgs=$(comm "-$comm" "$TMP_SYSTEM_AUR_PACKAGES" "$tmp_file")
    rm "$tmp_file"
  fi
  echo -e "\nRemoving unused $package packages"
  if [[ -n "$pkgs" ]]; then
    # shellcheck disable=SC2086
    sudo pacman -Rns $pkgs || true
  else
    echo " there is nothing to do"
  fi
}

function _install_aur() {
  local pkgs
  pkgs=$(comm -23 "$TMP_AUR_CONFIG" "$TMP_SYSTEM_AUR_PACKAGES")
  echo -e "\nInstalling AUR packages"
  if [[ -n "$pkgs" ]]; then
    # shellcheck disable=SC2086
    paru -Sa $pkgs || true
  else
    echo " there is nothing to do"
  fi
}

function main() {
  local leftover

  [[ ! -d "$MIRROR_DIR" ]] && mkdir -p "$MIRROR_DIR"

  _filter_aur_programs
  _read_config pacman && _install_pacman
  _read_config aur && _install_aur
  _remove_packages 13 pacman
  _remove_packages 13 AUR

  leftover=$(pacman -Qdtq)
  [[ -n "$leftover" ]] && {
    echo -e "\nRemoving leftovers\n"
    # shellcheck disable=SC2086
    sudo pacman -Rns $leftover
  }
}

while getopts ":h-p:" opt; do
  case "$opt" in
  h)
    help
    exit 0
    ;;
  -)
    break
    ;;
  p)
    MIRROR_PROFILE=$OPTARG
    ;;
  ?)
    echo "Error: Invalid option '-$OPTARG'" >&2
    exit 1
    ;;
  esac
done

shift $((OPTIND - 1))

while [[ $# -gt 0 ]]; do
  case "$1" in
  --help)
    help
    exit 0
    ;;
  *)
    if [ -z "$MIRROR_PROFILE" ]; then
      echo "Profile is not set"
      exit 1
    fi
    main
    ;;
  esac
done

if [ -z "$1" ]; then
  if [ -z "$MIRROR_PROFILE" ]; then
    echo "Profile is not set"
    exit 1
  fi
  main
fi
