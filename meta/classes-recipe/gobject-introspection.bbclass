#
# Copyright OpenEmbedded Contributors
#
# SPDX-License-Identifier: MIT
#

# Inherit this class in recipes to enable building their introspection files

# python3native is inherited to prevent introspection tools being run with
# host's python 3 (they need to be run with native python 3)
#
# This also sets up autoconf-based recipes to build introspection data (or not),
# depending on distro and machine features (see gobject-introspection-data class).
inherit python3native gobject-introspection-data

# meson: default option name to enable/disable introspection. This matches most
# project's configuration. In doubts - check meson_options.txt in project's
# source path.
GIR_MESON_OPTION ?= 'introspection'
GIR_MESON_ENABLE_FLAG ?= 'true'
GIR_MESON_DISABLE_FLAG ?= 'false'

# Define g-i options such that they can be disabled completely when GIR_MESON_OPTION is empty
GIRMESONTARGET = "-D${GIR_MESON_OPTION}=${@bb.utils.contains('GI_DATA_ENABLED', 'True', '${GIR_MESON_ENABLE_FLAG}', '${GIR_MESON_DISABLE_FLAG}', d)} "
GIRMESONBUILD = "-D${GIR_MESON_OPTION}=${GIR_MESON_DISABLE_FLAG} "
# Auto enable/disable based on GI_DATA_ENABLED
EXTRA_OECONF:prepend:class-target = "${@bb.utils.contains('GI_DATA_ENABLED', 'True', '--enable-introspection', '--disable-introspection', d)} "
EXTRA_OEMESON:prepend:class-target = "${@['', '${GIRMESONTARGET}'][d.getVar('GIR_MESON_OPTION') != '']}"
# When building native recipes, disable introspection, as it is not necessary,
# pulls in additional dependencies, and makes build times longer
EXTRA_OECONF:prepend:class-native = "--disable-introspection "
EXTRA_OECONF:prepend:class-nativesdk = "--disable-introspection "
EXTRA_OEMESON:prepend:class-native = "${@['', '${GIRMESONBUILD}'][d.getVar('GIR_MESON_OPTION') != '']}"
EXTRA_OEMESON:prepend:class-nativesdk = "${@['', '${GIRMESONBUILD}'][d.getVar('GIR_MESON_OPTION') != '']}"

# Generating introspection data depends on a combination of native and target
# introspection tools, and qemu to run the target tools.
DEPENDS:append:class-target = " ${@bb.utils.contains('GI_DATA_ENABLED', 'True', 'gobject-introspection qemu-native', '', d)}"

# Even when introspection is disabled, the gobject-introspection package is still needed for m4 macros.
DEPENDS:append = " gobject-introspection-native"

# This is used by introspection tools to find .gir includes
export XDG_DATA_DIRS = "${STAGING_DATADIR}:${STAGING_LIBDIR}"

do_configure:prepend:class-target () {
    # introspection.m4 pre-packaged with upstream tarballs does not yet
    # have our fixes
    mkdir -p ${S}/m4
    cp ${STAGING_DATADIR_NATIVE}/aclocal/introspection.m4 ${S}/m4
}

# .typelib files are needed at runtime and so they go to the main package (so
# they'll be together with libraries they support).
FILES:${PN}:append = " ${libdir}/girepository-*/*.typelib"

# .gir files go to dev package, as they're needed for developing (but not for
# running) things that depends on introspection.
FILES:${PN}-dev:append = " ${datadir}/gir-*/*.gir ${libdir}/gir-*/*.gir"
