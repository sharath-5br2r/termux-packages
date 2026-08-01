TERMUX_PKG_HOMEPAGE=https://www.winehq.org/
TERMUX_PKG_DESCRIPTION="A compatibility layer for running Windows programs"
TERMUX_PKG_LICENSE="LGPL-2.1"
TERMUX_PKG_LICENSE_FILE="LICENSE, NOTICES.md, COPYING.LIB"
TERMUX_PKG_MAINTAINER="@sharath-5br2r"
TERMUX_PKG_VERSION="11"
_REAL_VERSION="${TERMUX_PKG_VERSION/\~/-}"
_VERSION_FOLDER="$(test "${_REAL_VERSION:3:1}" = 0 && echo ${_REAL_VERSION:0:4} || echo ${_REAL_VERSION:0:3}x)"
TERMUX_PKG_SRCURL=git+https://github.com/sharath-5br2r/proton-wine.git
TERMUX_PKG_GIT_BRANCH=proton_11.0
TERMUX_PKG_DEPENDS="fontconfig, freetype, krb5, libandroid-spawn, libc++, libgmp, libgnutls, libxcb, libxcomposite, libxcursor, libxfixes, libxrender, libwayland, opengl, pulseaudio, sdl2 | sdl2-compat, vulkan-loader, xorg-xrandr"
TERMUX_PKG_ANTI_BUILD_DEPENDS="sdl2-compat, vulkan-loader"
TERMUX_PKG_BUILD_DEPENDS="libandroid-spawn-static, vulkan-loader-generic"
TERMUX_PKG_NO_STATICSPLIT=true
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_UPDATE_TAG_TYPE="newest-tag"
TERMUX_PKG_HOSTBUILD=true
TERMUX_PKG_EXTRA_HOSTBUILD_CONFIGURE_ARGS="
--without-x
--disable-tests
"

TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
ac_cv_header_linux_userfaultfd_h=no
ac_cv_path_GRADLE=no
enable_wineandroid_drv=no
enable_tools=yes
--prefix=$TERMUX_PREFIX/opt/proton-wine
--exec-prefix=$TERMUX_PREFIX/opt/proton-wine
--includedir=$TERMUX_PREFIX/opt/proton-wine/include
--libdir=$TERMUX_PREFIX/opt/proton-wine/lib
--with-wine-tools=$TERMUX_PKG_HOSTBUILD_DIR
--disable-win16
--enable-nls
--enable-wineandroid_drv=no
--disable-amd_ags_x64
--disable-tests
--without-alsa
--without-capi
--without-coreaudio
--without-cups
--without-dbus
--with-fontconfig
--with-freetype
--without-gettext
--with-gettextpo=no
--without-gphoto
--with-gnutls
--without-gstreamer
--without-inotify
--with-krb5
--with-mingw
--without-netapi
--without-opencl
--with-opengl
--without-osmesa
--without-oss
--without-pcap
--with-pthread
--with-pulse
--without-pcsclite
--without-piper
--without-sane
--with-sdl
--without-udev
--without-unwind
--without-usb
--without-v4l2
--with-vulkan
--with-wayland
--with-xcomposite
--with-xcursor
--with-xfixes
--without-xinerama
--with-xinput
--with-xinput2
--with-xrandr
--with-xrender
--without-xshape
--without-xshm
--without-xxf86vm
"

# Enable win64 on 64-bit arches.
if [ "$TERMUX_ARCH_BITS" = 64 ]; then
	TERMUX_PKG_EXTRA_CONFIGURE_ARGS+=" --enable-win64 --enable-archs=arm64ec,aarch64,i386"
fi

# Enable new WoW64 support on x86_64.
if [ "$TERMUX_ARCH" = "x86_64" ]; then
	TERMUX_PKG_EXTRA_CONFIGURE_ARGS+=" --enable-archs=i386,x86_64"
fi

# FIXME: This package doesn't work on arm since 8.x, but anyway
# FIXME: I'd like to compile it.
# TERMUX_PKG_EXCLUDED_ARCHES="arm"
_setup_llvm_mingw_toolchain() {
	# LLVM-mingw's version number must not be the same as the NDK's.
	local _llvm_mingw_version=22
	local _version="20260519"
	local _url="https://github.com/mstorsjo/llvm-mingw/releases/download/$_version/llvm-mingw-$_version-ucrt-ubuntu-22.04-x86_64.tar.xz"
	local _path="$TERMUX_PKG_CACHEDIR/$(basename $_url)"
	local _sha256sum=a48f8c2801508272ccde64d87a26747ecc5306623d9a080a42ed80dc61f79fa2
	termux_download $_url $_path $_sha256sum
	local _extract_path="$TERMUX_PKG_CACHEDIR/llvm-mingw-toolchain-$_llvm_mingw_version"
	if [ ! -d "$_extract_path" ]; then
		mkdir -p "$_extract_path"-tmp
		tar -C "$_extract_path"-tmp --strip-component=1 -xf "$_path"
		mv "$_extract_path"-tmp "$_extract_path"
	fi
	export PATH="$PATH:$_extract_path/bin"
}

termux_step_host_build() {
	# Setup llvm-mingw toolchain
	_setup_llvm_mingw_toolchain
  # Patches
  echo "Applying patches..."

    PATCHES=(
      # core patches
      "dlls_advapi32_advapi.c.patch"
      "dlls_amd_ags_x64_unixlib.c.patch"

      # dns
      "dlls_dnsapi_libresolv.c.patch"
      "dlls_dnsapi_record.c.patch"

      # midi
      "dlls_midimap_Makefile.in.patch"
      "dlls_midimap_midimap.c.patch"

      # nsiproxy
	  "dlls_nsiproxy.sys_nsi_common.h.patch"
      "dlls_nsiproxy.sys_ip.c.patch"
      "dlls_nsiproxy.sys_ndis.c.patch"

      # ntdll
      "dlls_ntdll_Makefile.in.patch"
      "dlls_ntdll_unix_fsync.c.patch"
      "dlls_ntdll_unix_loader.c.patch"
      "dlls_ntdll_unix_server.c.patch"
      "dlls_ntdll_unix_sync.c.patch"
      "dlls_ntdll_unix_virtual.c.patch"
	  "dlls_ntdll_unix_signal_x86_64.c.patch"
	  
	  # opengl32
	  "dlls_opengl32_unix_wgl.c.patch"

      # user32 / clipboard
      "dlls_user32_Makefile.in.patch"
      "dlls_win32u_clipboard.c.patch"

      # drivers
      "dlls_winebus.sys_bus_sdl.c.patch"
      "dlls_winepulse.drv_pulse.c.patch"

      # winex11
      "dlls_winex11.drv_bitblt.c.patch"
      "dlls_winex11.drv_keyboard.c.patch"
      "dlls_winex11.drv_mouse.c.patch"
      "dlls_winex11.drv_opengl.c.patch"
      "dlls_winex11.drv_window.c.patch"
      "dlls_winex11.drv_x11drv.h.patch"
      "dlls_winex11.drv_x11drv_main.c.patch"

      # wow64
      # "dlls_wow64_process.c.patch"
      "dlls_wow64_syscall.c.patch"

      # loader
      "loader_preloader.c.patch"

      # programs
      "programs_explorer_desktop.c.patch"
      "programs_wineboot_wineboot.c.patch"
      "programs_winebrowser_Makefile.in.patch"
      "programs_winebrowser_main.c.patch"
      "programs_winemenubuilder_winemenubuilder.c.patch"

      # server
      "server_Makefile.in.patch"
      "server_fsync.c.patch"
      "server_inproc_sync.c.patch"
      "server_main.c.patch"
      # "server_protocol.def.patch"
      "server_thread.c.patch"
      "server_unicode.c.patch"
	  
	  # esync
	  "dlls_ntdll_unix_esync.c.patch"
	  "dlls_ntdll_unix_esync.h.patch"
	  "server_esync.c.patch"
	  "server_esync.h.patch"
    )

    for patch in "${PATCHES[@]}"; do
      echo "----------------------------------------"
      echo "Applying: $patch"

      if git apply --check "$TERMUX_PKG_SRCDIR/android/patches/$patch" 2>/dev/null; then
        if git apply "$TERMUX_PKG_SRCDIR/android/patches/$patch"; then
          echo "SUCCESS: $patch applied"
        else
          echo "FAILED: error applying $patch"
        fi
      else
        echo "SKIPPED: $patch does not apply cleanly"
      fi
    done
    
	# Make host wine-tools
	"$TERMUX_PKG_SRCDIR/configure" ${TERMUX_PKG_EXTRA_HOSTBUILD_CONFIGURE_ARGS}
	make -j "$TERMUX_PKG_MAKE_PROCESSES" __tooldeps__ nls/all
}

termux_step_pre_configure() {
	# Setup llvm-mingw toolchain
	_setup_llvm_mingw_toolchain

	# Fix overoptimization
	CPPFLAGS="${CPPFLAGS/-Oz/}"
	CFLAGS="${CFLAGS/-Oz/}"
	CXXFLAGS="${CXXFLAGS/-Oz/}"

	# Disable hardening
	CPPFLAGS="${CPPFLAGS/-fstack-protector-strong/}"
	CFLAGS="${CFLAGS/-fstack-protector-strong/}"
	CXXFLAGS="${CXXFLAGS/-fstack-protector-strong/}"
	LDFLAGS="${LDFLAGS/-Wl,-z,relro,-z,now/}"

	LDFLAGS+=" -landroid-spawn"

	# https://github.com/termux-user-repository/tur/commit/9388bf3599bba33d7bd052cab0679fe9cd5917d2#commitcomment-176464300
	LDFLAGS+=" -Wl,--rosegment"

	if [ "$TERMUX_ARCH" = "x86_64" ]; then
		mkdir -p "$TERMUX_PKG_TMPDIR/bin"
		cat <<- EOF > "$TERMUX_PKG_TMPDIR/bin/x86_64-linux-android-clang"
			#!/bin/bash
			set -- "\${@/-mabi=ms/}"
			exec $TERMUX_STANDALONE_TOOLCHAIN/bin/x86_64-linux-android-clang "\$@"
		EOF
		chmod +x "$TERMUX_PKG_TMPDIR/bin/x86_64-linux-android-clang"
		export PATH="$TERMUX_PKG_TMPDIR/bin:$PATH"
	fi
}

termux_step_make() {
	make -j $TERMUX_PKG_MAKE_PROCESSES
}

termux_step_make_install() {
	make -j $TERMUX_PKG_MAKE_PROCESSES install

	# Create proton-wine script
	mkdir -p $TERMUX_PREFIX/bin
	cat << EOF > $TERMUX_PREFIX/bin/proton-wine
#!$TERMUX_PREFIX/bin/env sh

exec $TERMUX_PREFIX/opt/proton-wine/bin/wine "\$@"

EOF
	chmod +x $TERMUX_PREFIX/bin/proton-wine
}
