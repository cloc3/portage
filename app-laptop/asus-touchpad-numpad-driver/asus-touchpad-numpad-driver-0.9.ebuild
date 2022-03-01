# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
PYTHON_COMPAT=( python3_{8..10} )

inherit systemd python-single-r1 linux-info

DESCRIPTION="py service which enables switching between numpad and touchpad for Asus laptops"
HOMEPAGE="https://github.com/mohamed-badaoui/asus-touchpad-numpad-driver" # commit: d80980af6ef776ee6acf42c193689f207caa7968
SRC_URI="https://github.com/cloc3/portage/raw/main/distfiles/${P}.zip"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"
IUSE="systemd openrc -test"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

RDEPEND="
	${PYTHON_DEPS}
	dev-python/python-libevdev
	sys-apps/i2c-tools
	systemd? ( sys-apps/systemd )
	openrc? ( sys-apps/openrc )
	"

BDEPEND="${RDEPENDS}"

#PROPERTIES="interactive"

PATCHES=(
	"${FILESDIR}/initService.patch"
)

CONFIG_CHECK="
	~INPUT_UINPUT
	~I2C_CHARDEV
"

S="${WORKDIR}/${PN}-main"

pkg_prerm() {
	[ -f /lib/systemd/system/${PN}.service ] && {
		systemctl stop ${PN}
		systemctl disable ${PN}
	}
	[ -f /etc/init.d/system/${PN} ] && {
		rc-service ${PN} stop
		rc-update delete ${PN}
	}
}

src_install() {
	exeinto /usr/share/${PN}
	doexe "${FILESDIR}/touchReset.sh"
	doexe "${FILESDIR}/loadModules.sh"
	python_setup
	python_domodule numpad_layouts
	use test && python_doexe tests/test_brightness.py
	python_doexe asus_touchpad.py
	use systemd && {
		systemd_newunit asus_touchpad.service "${PN}.service"
		systemd_install_serviced "${FILESDIR}/${PN}.service.conf"
	}
	use openrc && {
		newinitd "${FILESDIR}/${PN}.initd" "${PN}"
		newconfd "${FILESDIR}/${PN}.confd" "${PN}"
	}
	default
}

pkg_postinst() {
	use systemd && {
		elog ""
		elog "To start systemd service do:"
		elog "# systemctl enable ${PN}.service"
		elog "# systemctl start ${PN}.service"
		elog ""
	}
	use openrc && {
		elog ""
		elog "To start openrc service do:"
		elog "# rc-update add ${PN}" default
		elog "# rc-service ${PN} start"
		elog ""
	}
	use test && {
		elog ""
		elog "For testing your touchpad do:"
		elog "# modprobe -v uinput"
		elog "# modprobe -v i2c-dev"
		elog "test_brightenss.py"
		elog ""
	}
}
