#!/usr/bin/env bash

set -euo pipefail

CRITEST_BRANCH_DEFAULT=master
ARCH=$(uname -m)
# keep the first one only
GOPATH="${GOPATH%%:*}"

# add bin folder into PATH.
export PATH="${GOPATH}/bin:${PATH}"

# critest::check_version checks the command and the version.
critest::check_version() {
  local has_installed version

  has_installed="$(command -v critest || echo false)"
  if [[ "${has_installed}" = "false" ]]; then
    echo false
    exit 0
  fi

  version="$(critest -version | head -n 1 | cut -d " " -f 3)"
  if [[ "${CRITEST_VERSION}" != "${version}" ]]; then
    echo false
    exit 0
  fi

  echo true
}

# critest::install downloads the package and build.
critest::install() {
  local workdir pkg CRITOOLS_REPO

  pkg="github.com/kubernetes-sigs/cri-tools"
  CRITOOLS_REPO="github.com/DikshantJajedi/cri-tools"
  workdir="${GOPATH}/src/${pkg}"

  if [ ! -d "${workdir}" ]; then
    mkdir -p "${workdir}"
    cd "${workdir}"
    git clone https://${CRITOOLS_REPO} .
  fi

  cd "${workdir}"
  git fetch --all
  echo ">>>> checkout <<<<"
  git checkout "${CRITEST_BRANCH_DEFAULT}"
  echo ">>>> make running <<<<"
  if [[ "${ARCH}" == "aarch64" ]]; then
    wget -O critest https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.19.0/critest-v1.19.0-linux-arm64.tar.gz
  else
    wget -O critest https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.19.0/critest-v1.19.0-linux-amd64.tar.gz
  fi
  #wget -O critest https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.19.0/critest-v1.19.0-linux-$(arch1).tar.gz
  tar -xvf critest
  cp critest /usr/local/bin/critest
  #make
  echo ">>>> make completed <<<<"
  cd -
  echo ">>>> DONEEEEEEEEEE <<<<"
}

# critest::install_ginkgo installs ginkgo if missing.
critest::install_ginkgo() {
  hack/install/install_ginkgo.sh
}

# critest::install_socat installs socat if missing.
critest::install_socat() {
  sudo apt-get install -y socat
}

main() {
  critest::install_ginkgo
  critest::install_socat

  local has_installed

  CRITEST_VERSION="1.19.0"
  has_installed="$(critest::check_version)"
  if [[ "${has_installed}" = "true" ]]; then
    echo "critest-${CRITEST_VERSION} has been installed."
    exit 0
  fi

  echo ">>>> install critest-${CRITEST_VERSION} <<<<"
  critest::install
  echo ">>>> install done <<<<"

  #command -v critest > /dev/null
  #command --help
  #command -version critest
  #command -version critest
  #echo ">>>> command checked <<<<"
}

main "$@"
