# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-emulation/lxc/lxc-0.8.0-r1.ebuild,v 1.3 2013/09/10 05:22:55 maekke Exp $

EAPI=5

AUTOTOOLS_AUTORECONF=true
AUTOTOOLS_IN_SOURCE_BUILD=1

inherit autotools-utils eutils git-2 linux-info versionator flag-o-matic

DESCRIPTION="LinuX Containers userspace utilities"
HOMEPAGE="http://lxc.sourceforge.net/"
SRC_URI=""
EGIT_REPO_URI="https://github.com/lxc/lxc.git"

LICENSE="LGPL-3"
SLOT="0"
KEYWORDS=""
IUSE="examples"

RDEPEND="sys-libs/libcap"

DEPEND="${RDEPEND}
	app-text/docbook-sgml-utils
	>=sys-kernel/linux-headers-3.2"

RDEPEND="${RDEPEND}
	sys-apps/util-linux
	app-misc/pax-utils
	>=sys-apps/openrc-0.9.9.1
	virtual/awk"

CONFIG_CHECK="~CGROUPS ~CGROUP_DEVICE
	~CPUSETS ~CGROUP_CPUACCT
	~RESOURCE_COUNTERS
	~CGROUP_SCHED

	~NAMESPACES
	~IPC_NS ~USER_NS ~PID_NS

	~DEVPTS_MULTIPLE_INSTANCES
	~CGROUP_FREEZER
	~UTS_NS ~NET_NS
	~VETH ~MACVLAN

	~POSIX_MQUEUE
	~!NETPRIO_CGROUP

	~!GRKERNSEC_CHROOT_MOUNT
	~!GRKERNSEC_CHROOT_DOUBLE
	~!GRKERNSEC_CHROOT_PIVOT
	~!GRKERNSEC_CHROOT_CHMOD
	~!GRKERNSEC_CHROOT_CAPS
"

#S="${WORKDIR}/${MY_P}"

ERROR_DEVPTS_MULTIPLE_INSTANCES="CONFIG_DEVPTS_MULTIPLE_INSTANCES:	needed for pts inside container"

ERROR_CGROUP_FREEZER="CONFIG_CGROUP_FREEZER:	needed to freeze containers"

ERROR_UTS_NS="CONFIG_UTS_NS:	needed to unshare hostnames and uname info"
ERROR_NET_NS="CONFIG_NET_NS:	needed for unshared network"

ERROR_VETH="CONFIG_VETH:	needed for internal (host-to-container) networking"
ERROR_MACVLAN="CONFIG_MACVLAN:	needed for internal (inter-container) networking"

ERROR_POSIX_MQUEUE="CONFIG_POSIX_MQUEUE:	needed for lxc-execute command"

ERROR_NETPRIO_CGROUP="CONFIG_NETPRIO_CGROUP:	as of kernel 3.3 and lxc 0.8.0_rc1 this causes LXCs to fail booting."

ERROR_GRKERNSEC_CHROOT_MOUNT=":CONFIG_GRKERNSEC_CHROOT_MOUNT	some GRSEC features make LXC unusable see postinst notes"
ERROR_GRKERNSEC_CHROOT_DOUBLE=":CONFIG_GRKERNSEC_CHROOT_DOUBLE	some GRSEC features make LXC unusable see postinst notes"
ERROR_GRKERNSEC_CHROOT_PIVOT=":CONFIG_GRKERNSEC_CHROOT_PIVOT	some GRSEC features make LXC unusable see postinst notes"
ERROR_GRKERNSEC_CHROOT_CHMOD=":CONFIG_GRKERNSEC_CHROOT_CHMOD	some GRSEC features make LXC unusable see postinst notes"
ERROR_GRKERNSEC_CHROOT_CAPS=":CONFIG_GRKERNSEC_CHROOT_CAPS	some GRSEC features make LXC unusable see postinst notes"

DOCS=(AUTHORS CONTRIBUTING MAINTAINERS TODO README doc/FAQ.txt)

src_prepare() {
	sed \
		-e "/PKG_CHECK_MODULES/s:python3:python-3.3:g" \
		-i configure.ac || die

	autotools-utils_src_prepare
}

src_configure() {
	append-flags -fno-strict-aliasing

	local myeconfargs=(
		--localstatedir=/var
		--bindir=/usr/sbin
		--docdir=/usr/share/doc/${PF}
		--disable-rpath
		--enable-doc
		--with-config-path=/etc/lxc
		--with-rootfs-path=/usr/lib/lxc/rootfs
		--with-log-path=/var/log/lxc
		--with-distro=gentoo
		--disable-apparmor
		--disable-selinux
		--disable-lua
		--enable-python
#		--enable-seccomp
		--disable-seccomp
		$(use_enable examples)
		)
	autotools-utils_src_configure
}

_src_install() {
	default

#	rm -r "${D}"/usr/sbin/lxc-setcap \
#		|| die "unable to remove lxc-setcap"

	keepdir /etc/lxc /usr/lib/lxc/rootfs /var/log/lxc

	find "${D}" -name '*.la' -delete

	# Gentoo-specific additions!
	newinitd "${FILESDIR}/${PN}.initd.2" ${PN}
	keepdir /var/log/lxc
}

pkg_postinst() {
	elog "There is an init script provided with the package now; no documentation"
	elog "is currently available though, so please check out /etc/init.d/lxc ."
	elog "You _should_ only need to symlink it to /etc/init.d/lxc.configname"
	elog "to start the container defined into /etc/lxc/configname.conf ."
	elog "For further information about LXC development see"
	elog "http://blog.flameeyes.eu/tag/lxc" # remove once proper doc is available
	elog ""
	ewarn "With version 0.7.4, the mountpoint syntax came back to the one used by 0.7.2"
	ewarn "and previous versions. This means you'll have to use syntax like the following"
	ewarn ""
	ewarn "    lxc.rootfs = /container"
	ewarn "    lxc.mount.entry = /usr/portage /container/usr/portage none bind 0 0"
	ewarn ""
	ewarn "To use the Fedora, Debian and (various) Ubuntu auto-configuration scripts, you"
	ewarn "will need sys-apps/yum or dev-util/debootstrap."
	ewarn ""
	ewarn "Some GrSecurity settings in relation to chroot security will cause LXC not to"
	ewarn "work, while others will actually make it much more secure. Please refer to"
	ewarn "Diego Elio PettenÃ²'s weblog at http://blog.flameeyes.eu/tag/lxc for further"
	ewarn "details."
}