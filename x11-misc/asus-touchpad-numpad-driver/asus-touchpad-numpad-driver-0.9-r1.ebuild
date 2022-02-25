# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
PYTHON_COMPAT=( python3_{8,9} )

inherit readme.gentoo-r1 systemd

DESCRIPTION="py service which enables switching between numpad and touchpad for Asus laptops"
HOMEPAGE="https://github.com/mohamed-badaoui/asus-touchpad-numpad-driver" # commit: d80980af6ef776ee6acf42c193689f207caa7968
SRC_URI="https://github.com/cloc3/portage/raw/main/x11-misc/${PN}/${P}.zip"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~mips ~ppc ~ppc64 ~riscv ~x86"
IUSE="startTouchpadOnTheFly systemd openrc"

DEPEND="
	dev-python/python-libevdev
	sys-apps/i2c-tools
	"

#RDEPEND="${DEPEND}"

PROPERTIES="interactive"

PATCHES=(
	"${FILESDIR}/initService.patch"
)

pkg_pretend() {
	elog ""
	elog "warn:"
	elog "needed modules to have numpad working:"
	elog "i2c_dev and uinput"
	elog ""
}

src_unpack() {
	default
	mv "./${PN}-main" "./${P}"
}

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
	exeinto /usr/share/asus_touchpad_numpad-driver
	doexe asus_touchpad.py
	doexe "${FILESDIR}/loadModules.sh"
	doexe "${FILESDIR}/touchReset.sh"
	insinto /usr/share/asus_touchpad_numpad-driver
	doins -r numpad_layouts
	doins -r tests
	use systemd && {
		systemd_newunit asus_touchpad.service ${PN}.service
	}
	use openrc && {
		newinitd "${FILESDIR}/${PN}.initd" "${PN}"
		newconfd "${FILESDIR}/${PN}.confd" "${PN}"
	}
	default
}

pkg_postinst() {
	use startTouchpadOnTheFly && {
		modprobe -v i2c-dev
		modprobe -v uinput
		[ -d /var/db/pkg/sys-apps/systemd-* ] && {
			use systemd && {
				systemctl enable ${PN}
				systemctl start ${PN}
			} || {
				elog "To start systemd service do:"
				elog "# systemctl enable ${PN}.service"
				elog "# systemctl start ${PN}.service"
				elog
			}
			use openrc && {
				elog ""
				elog "systemd found: cannot start openrc service"
				elog ""
			}
		}
		[ -d /var/db/pkg/sys-apps/openrc-* ] && {
			use openrc && {
				rc-update add ${PN} default
				rc-service ${PN} start
			} || {
				elog "To start openrc service do:"
				elog "# rc-update add ${PN}" default
				elog "# rc-service ${PN} start"
				elog ""
			}
			use systemd && {
				elog ""
				elog "openrc found: cannot start systemd service"
				elog ""
			}
		}
	}
}
