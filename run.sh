#!/usr/bin/env bash

# only this needs changing
ZFS_VERSION=2.1.11
ZFS_RELEASE=1
EL_NAME=rocky

# for mock config
EL_DIST=$(rpm --eval %{dist})
EL_DIST="${EL_DIST//\./}"
EL_MARCH=$(rpm --eval %{_arch})
EL_VERSION="${EL_DIST//el/}"
MOCK_CONFIG="${EL_NAME}-${EL_VERSION}-${EL_MARCH}"

# for downloading ZFS SRPMs
COMMON_URL="http://download.zfsonlinux.org/epel/${EL_VERSION}/SRPMS"
ZFS_PKG_INFIX="${ZFS_VERSION}-${ZFS_RELEASE}.${EL_DIST}"
SRPM_PKG_SUFFIX="${ZFS_PKG_INFIX}.src.rpm"
ZFS_SRPM_PKG="zfs-${SRPM_PKG_SUFFIX}"
ZFS_SRPM_PKG_URL="${COMMON_URL}/${ZFS_SRPM_PKG}"
ZFS_DKMS_SRPM_PKG="zfs-dkms-${SRPM_PKG_SUFFIX}"
ZFS_DKMS_SRPM_PKG_URL="${COMMON_URL}/${ZFS_DKMS_SRPM_PKG}"

# for mock building and copying RPMs back to 'out/'
NOARCH_PKG_SUFFIX="${ZFS_PKG_INFIX}.noarch.rpm"
ZFS_DKMS_NOARCH_PKG="zfs-dkms-${NOARCH_PKG_SUFFIX}"

INSTALLED_PKGS=$(dnf list installed)
ORIG_USER=$USER
CURRENT_GROUPS=$(groups ${USER})

if [[ ! "${INSTALLED_PKGS[@]}" =~ "mock" ]]; then
	sudo dnf install -y mock
fi
if [[ ! "${INSTALLED_PKGS[@]}" =~ "rpm-build" ]]; then
	sudo dnf install -y rpm-build
fi
if [[ ! "${CURRENT_GROUPS[@]}" =~ "mock" ]]; then
	sudo usermod -aG mock ${ORIG_USER}
	echo "Please log-out and log-in again to make sure that '$USER' is in the group 'mock'"
	exit 1
fi

[[ -d out ]] || rm -rf out
mkdir out

[[ -f ${ZFS_SRPM_PKG} ]] || wget ${ZFS_SRPM_PKG_URL}
[[ -f ${ZFS_DKMS_SRPM_PKG} ]] || wget ${ZFS_DKMS_SRPM_PKG_URL}

mock --root ${MOCK_CONFIG} --init --update

mock --root ${MOCK_CONFIG} ${ZFS_SRPM_PKG}
cp /var/lib/mock/${MOCK_CONFIG}/result/*.rpm out/

mock --root ${MOCK_CONFIG} ${ZFS_DKMS_SRPM_PKG}
cp /var/lib/mock/${MOCK_CONFIG}/result/${ZFS_DKMS_NOARCH_PKG} out/

rm -vf out/*.src.rpm
