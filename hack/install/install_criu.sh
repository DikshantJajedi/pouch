#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
source "./check.sh"

criu::ubuntu::install_dependencies() {
  apt-get install -y -q \
    build-essential \
    libnet1-dev \
    libprotobuf-dev \
    libprotobuf-c-dev \
    protobuf-c-compiler \
    protobuf-compiler \
    python-protobuf \
    libnl-3-dev \
    libcap-dev \
    asciidoc
}

# criu::ubuntu::install will install criu from source.
criu::ubuntu::install() {
  #apt-get install -y -q criu
  local tmpdir tag

  tag="v3.10"
  tmpdir="$(mktemp -d /tmp/criu-build-XXXXXX)"

  git clone https://github.com/protocolbuffers/protobuf
  cd protobuf/
  ./autogen.sh && ./configure && make
  cd ..
  git clone https://github.com/checkpoint-restore/criu.git "${tmpdir}/criu"
  cd "${tmpdir}/criu"
  git checkout "${tag}" -b "${tag}"
  make
  make install
}

main() {
  local os_dist has_installed

  has_installed="$(command -v criu || echo false)"
  if [[ "${has_installed}" != "false" ]]; then
    echo "criu has been installed!"
    exit 0
  fi

  echo ">>>> install criu <<<<"

  os_dist="$(detect_os)"
  if [[ "${os_dist}" = "Ubuntu" ]]; then
    criu::ubuntu::install > /dev/null
  else
    echo "will support redhat soon"
    exit 0
  fi

  # final check
  command -v criu > /dev/null

  echo
}

main
