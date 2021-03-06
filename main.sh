#!/usr/bin/env bash

#!/bin/bash

declare -r GITHUB_REPOSITORY="eernie/homeserver"

declare -r DOTFILES_ORIGIN="git@github.com:$GITHUB_REPOSITORY.git"
declare -r DOTFILES_TARBALL_URL="https://github.com/$GITHUB_REPOSITORY/tarball/master"
declare -r DOTFILES_UTILS_URL="https://raw.githubusercontent.com/$GITHUB_REPOSITORY/master/src/utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

declare dotfilesDirectory="$HOME/.homeserver_install"
declare skipQuestions=false

# ----------------------------------------------------------------------
# | Helper Functions                                                   |
# ----------------------------------------------------------------------

download() {

  local url="$1"
  local output="$2"

  if command -v "curl" &>/dev/null; then

    curl -LsSo "$output" "$url" &>/dev/null
    #     │││└─ write output to file
    #     ││└─ show error messages
    #     │└─ don't show the progress meter
    #     └─ follow redirects

    return $?

  elif command -v "wget" &>/dev/null; then

    wget -qO "$output" "$url" &>/dev/null
    #     │└─ write output to file
    #     └─ don't show output

    return $?
  fi

  return 1

}

download_dotfiles() {

  local tmpFile=""

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  print_in_purple "\n • Download and extract archive\n\n"

  tmpFile="$(mktemp /tmp/XXXXX)"

  download "$DOTFILES_TARBALL_URL" "$tmpFile"
  print_result $? "Download archive" "true"
  printf "\n"

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  if ! $skipQuestions; then

    ask_for_confirmation "Do you want to store the dotfiles in '$dotfilesDirectory'?"

    if ! answer_is_yes; then
      dotfilesDirectory=""
      while [ -z "$dotfilesDirectory" ]; do
        ask "Please specify another location for the dotfiles (path): "
        dotfilesDirectory="$(get_answer)"
      done
    fi

    # Ensure the `dotfiles` directory is available

    while [ -e "$dotfilesDirectory" ]; do
      ask_for_confirmation "'$dotfilesDirectory' already exists, do you want to overwrite it?"
      if answer_is_yes; then
        rm -rf "$dotfilesDirectory"
        break
      else
        dotfilesDirectory=""
        while [ -z "$dotfilesDirectory" ]; do
          ask "Please specify another location for the dotfiles (path): "
          dotfilesDirectory="$(get_answer)"
        done
      fi
    done

    printf "\n"

  else

    rm -rf "$dotfilesDirectory" &>/dev/null

  fi

  mkdir -p "$dotfilesDirectory"
  print_result $? "Create '$dotfilesDirectory'" "true"

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  # Extract archive in the `dotfiles` directory.

  extract "$tmpFile" "$dotfilesDirectory"
  print_result $? "Extract archive" "true"

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  rm -rf "$tmpFile"
  print_result $? "Remove archive"

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  cd "$dotfilesDirectory/src" ||
    return 1

}

download_utils() {

  local tmpFile=""

  tmpFile="$(mktemp /tmp/XXXXX)"

  download "$DOTFILES_UTILS_URL" "$tmpFile" &&
    . "$tmpFile" &&
    rm -rf "$tmpFile" &&
    return 0

  return 1

}

extract() {

  local archive="$1"
  local outputDir="$2"

  if command -v "tar" &>/dev/null; then
    tar -zxf "$archive" "$outputDir"
    return $?
  fi

  return 1

}

# ----------------------------------------------------------------------
# | Main                                                               |
# ----------------------------------------------------------------------

main() {

  # Ensure that the following actions
  # are made relative to this file's path.

  cd "$(dirname "${BASH_SOURCE[0]}")" ||
    exit 1

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  # Load utils

  if [ -x "src/utils.sh" ]; then
    . "src/utils.sh" || exit 1
  else
    download_utils || exit 1
  fi

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  ask_for_sudo

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  # Check if this script was run directly (./<path>/setup.sh),
  # and if not, it most likely means that the dotfiles were not
  # yet set up, and they will need to be downloaded.

  printf "%s" "${BASH_SOURCE[0]}" | grep "setup.sh" &>/dev/null ||
    download_dotfiles

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

}

main "$@"
