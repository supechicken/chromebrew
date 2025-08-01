require 'package'

class Sommelier < Package
  description 'Sommelier works by redirecting X11 programs to the built-in ChromeOS Exo Wayland server.'
  homepage 'https://chromium.googlesource.com/chromiumos/platform2/+/HEAD/vm_tools/sommelier/'
  version "20250422-#{CREW_LLVM_VER}"
  license 'BSD-Google'
  compatibility 'aarch64 armv7l x86_64'
  source_url 'https://chromium.googlesource.com/chromiumos/platform2.git'
  git_hashtag '71fec9e3432237147309d9e2e82cf6841ba03d0f'
  binary_compression 'tar.zst'

  binary_sha256({
    aarch64: 'f5419b5787ec89c9d252597d66ac101942c87cd2c5fb423d17566cf87c7ea4bf',
     armv7l: 'f5419b5787ec89c9d252597d66ac101942c87cd2c5fb423d17566cf87c7ea4bf',
     x86_64: 'd31a50da5ec4463c8fdeca8189fa7797804e2eb5b431c7b78802c2179529f9a3'
  })

  depends_on 'gcc_lib' # R
  depends_on 'glibc' # R
  depends_on 'libdrm' # R
  depends_on 'libxcb' # R
  depends_on 'libxcomposite' => :build
  depends_on 'libxfixes' => :build
  depends_on 'libxkbcommon' # R
  depends_on 'llvm_dev' => :build
  depends_on 'mesa' # R
  depends_on 'pixman' # R
  depends_on 'procps' # for pgrep in wrapper script
  depends_on 'psmisc' # L
  depends_on 'py3_jinja2' => :build
  depends_on 'wayland' # R
  depends_on 'wayland_info' # L
  depends_on 'xauth' # L
  depends_on 'xhost' # for xhost in sommelierd script
  depends_on 'xkbcomp' # The sommelier log complains if this isn't installed.
  depends_on 'xorg_xset' # for xset in wrapper script
  depends_on 'xsetroot' # for xsetroot in /usr/local/etc/sommelierrc script
  depends_on 'xwayland' # L

  no_shrink
  print_source_bashrc

  def self.preflight
    return if File.socket?('/var/run/chrome/wayland-0') || CREW_IN_CONTAINER

    abort 'This package is not compatible with your device :/'.lightred
  end

  def self.patch
    # This patch fixes:
    #   wl_registry@2: error 0: invalid version for global xdg_wm_base (41): have 1, wanted 3
    #   sommelier.elf: ../sommelier-window.cc:412: void sl_window_update(struct sl_window *): Assertion `ctx->xdg_shell' failed.
    sommelier_patch = <<~'SOMMELIER_PATCH_EOF'
      diff -Npaur a/sommelier.cc b/sommelier.cc
      --- a/sommelier.cc	2024-03-07 16:44:13.513582795 -0500
      +++ b/sommelier.cc	2024-03-07 16:46:42.699788185 -0500
      @@ -108,6 +108,8 @@ struct sl_data_source {

       static const char STEAM_APP_CLASS_PREFIX[] = "steam_app_";

      +char xdg_shell_interface[20] = "xdg_wm_base";
      +
       int sl_open_wayland_socket(const char* socket_name,
                                  struct sockaddr_un* addr,
                                  int* lock_fd,
      @@ -592,7 +594,7 @@ void sl_registry_handler(void* data,
             data_device_manager->host_global =
                 sl_data_device_manager_global_create(ctx);
           }
      -  } else if (strcmp(interface, "xdg_wm_base") == 0) {
      +  } else if (strcmp(interface, xdg_shell_interface) == 0) {
           struct sl_xdg_shell* xdg_shell =
               static_cast<sl_xdg_shell*>(malloc(sizeof(struct sl_xdg_shell)));
           assert(xdg_shell);
      @@ -4014,6 +4016,8 @@ int real_main(int argc, char** argv) {
             ctx.use_virtgpu_channel = true;
           } else if (strstr(arg, "--noop-driver") == arg) {
             noop_driver = true;
      +    } else if (strstr(arg, "--xdg-shell-v6") == arg) {
      +      strcpy(xdg_shell_interface, "zxdg_shell_v6");
           } else if (strstr(arg, "--stable-scaling") == arg) {
             ctx.stable_scaling = true;
           } else if (strstr(arg, "--viewport-resize") == arg) {
      diff -Npaur a/sommelier.h b/sommelier.h
      --- a/sommelier.h	2024-03-07 16:44:17.017540640 -0500
      +++ b/sommelier.h	2024-03-07 16:48:46.286301715 -0500
      @@ -22,7 +22,8 @@
       #include "weak-resource-ptr.h"          // NOLINT(build/include_directory)

       #define SOMMELIER_VERSION "0.20"
      -#define APPLICATION_ID_FORMAT_PREFIX "org.chromium.guest_os.%s"
      +#define XDG_SHELL_VERSION 1u
      +#define APPLICATION_ID_FORMAT_PREFIX "org.chromebrew.%s"
       #define NATIVE_WAYLAND_APPLICATION_ID_FORMAT \
         APPLICATION_ID_FORMAT_PREFIX ".wayland.%s"
    SOMMELIER_PATCH_EOF

    Dir.chdir 'vm_tools/sommelier' do
      File.write('sommelier.patch', sommelier_patch)
      system 'patch -p1 -i sommelier.patch'
    end
  end

  def self.build
    case ARCH
    when 'armv7l', 'aarch64'
      @peer_cmd_prefix = '/lib/ld-linux-armhf.so.3'
    when 'x86_64'
      @peer_cmd_prefix = '/lib64/ld-linux-x86-64.so.2'
    end
    Dir.chdir('vm_tools/sommelier') do
      # lld is needed so libraries linked to system libraries (e.g. libgbm.so) can be linked against, since those are required for graphics acceleration.

      system <<~BUILD
        env CC=clang CXX=clang++ \
          meson setup #{CREW_MESON_OPTIONS.gsub('-ffat-lto-objects', '')} \
          -Dcommit_loop_fix=true \
          -Db_asneeded=false \
          -Db_lto=true \
          -Db_lto_mode=thin \
          -Dwith_tests=false \
          -Dxwayland_path=#{CREW_PREFIX}/bin/Xwayland \
          -Dxwayland_gl_driver_path=#{CREW_LIB_PREFIX}/dri \
          -Ddefault_library=both \
          builddir
      BUILD

      system 'meson configure --no-pager builddir'
      system "#{CREW_NINJA} -C builddir"

      FileUtils.mkdir_p 'builddir'
      Dir.chdir('builddir') do
        system 'curl -L "https://chromium.googlesource.com/chromiumos/containers/sommelier/+/fbdefff6230026ac333eac0924d71cf824e6ecd8/sommelierrc?format=TEXT" | base64 --decode > sommelierrc'
        system "sed -i '/exit 0/d' sommelierrc"

        File.write 'sommelierenv', <<~SOMMELIERENVEOF
          set -a
          GDK_BACKEND=${GDK_BACKEND:-x11}
          # Adjust settings for container usage if necessary.
          if [ -f '/.dockerenv' ]; then
            CLUTTER_BACKEND=x11
            set +a
            # Return or exit depending upon whether script was sourced.
            (return 0 2>/dev/null) && return 0 || exit 0
          fi
          SOMMELIER_ACCELERATORS='Super_L,<Alt>bracketleft,<Alt>bracketright'
          WAYLAND_DISPLAY=wayland-0
          XDG_RUNTIME_DIR=/var/run/chrome
          SOMMELIER_VM_IDENTIFIER=chromebrew
          if grep -q GenuineIntel /proc/cpuinfo ;then
            check_linux_version() {
                maj_ver=$1
                min_ver=$2
                version_good=$(uname -r | awk 'BEGIN{ FS="."};
                { if ($1 < '"${maj_ver}"') { print "N"; }
                  else if ($1 == '"${maj_ver}"') {
                      if ($2 < '"${min_ver}"') { print "N"; }
                      else { print "Y"; }
                  }
                  else { print "Y"; }
                }')

                if [ "$version_good" = "N" ]; then
                    return 1
                fi
            }
            case "$(uname -m)" in
            x86_64)
              if ! check_linux_version 4 16; then
              :
              # Mesa > 22.0 does not support i965
              # MESA_LOADER_DRIVER_OVERRIDE=i965
              elif check_linux_version 5 10; then
                MESA_LOADER_DRIVER_OVERRIDE=iris
              fi
            ;;
            esac
          fi
          CLUTTER_BACKEND=${CLUTTER_BACKEND:-wayland}
          DISPLAY=${DISPLAY:-:0}
          set +a
        SOMMELIERENVEOF

        # Create local startup and shutdown scripts

        # sommelier_sh
        # This file via:
        # crostini: /opt/google/cros-containers/bin/sommelier
        # https://source.chromium.org/chromium/chromium/src/+/master:third_party/chromite/third_party/lddtree.py;drc=46da9a8dfce28c96765dc7d061f0c6d7a52e7352;l=146
        File.write 'sommelier_sh', <<~SOMMELIERSHEOF
          #!/bin/bash
          function readlink(){
            coreutils --coreutils-prog=readlink "$@"
          }

          if base=$(readlink "$0" 2>/dev/null); then
            case $base in
            /*) base=$(readlink -f "$0" 2>/dev/null);; # if $0 is abspath symlink, make symlink fully resolved.
            *)  base=$(dirname "$0")/"${base}";;
            esac
          else
            case $0 in
            /*) base=$0;;
            *)  base=${PWD:-`pwd`}/$0;;
            esac
          fi
          basedir=${base%/*}
          LD_ARGV0_REL="../bin/sommelier" \
            exec "${basedir}/..#{@peer_cmd_prefix}" \
              --library-path \
              "${basedir}/../#{ARCH_LIB}" \
              --inhibit-rpath '' \
              "${base}.elf" \
              "$@"
        SOMMELIERSHEOF

        # sommelierd
        File.write 'sommelierd', <<~SOMMELIERDEOF
          #!/bin/bash -a
          set -a
          source ${CREW_PREFIX}/etc/env.d/sommelier
          set +a
          mkdir -p #{CREW_PREFIX}/var/{log,run}
          checksommelierwayland () {
            [[ -f "#{CREW_PREFIX}/var/run/sommelier-wayland.pid" ]] || return 1
            /sbin/ss --unix -a -p | grep "\b$(cat #{CREW_PREFIX}/var/run/sommelier-wayland.pid)" | grep wayland &>/dev/null
          }
          checksommelierxwayland () {
            DISPLAY="${DISPLAY}" timeout 1s xset q &>/dev/null
          }

          ## As per https://www.reddit.com/r/chromeos/comments/8r5pvh/crouton_sommelier_openjdk_and_oracle_sql/e0pfknx/
          ## One needs a second sommelier instance for wayland clients since at some point wl-drm was not implemented
          ## in ChromeOS's wayland compositor.
          #if ! checksommelierwayland ; then
          #  pkill -F #{CREW_PREFIX}/var/run/sommelier-wayland.pid &>/dev/null
          #  rm ${XDG_RUNTIME_DIR}/wayland-1*
          #  sommelier --parent \
          #    --peer-cmd-prefix="#{CREW_PREFIX}#{@peer_cmd_prefix}" \
          #    --drm-device=/dev/dri/renderD128 --shm-driver=noop \
          #    --data-driver=noop --display=wayland-0 --socket=wayland-1 \
          #    --virtwl-device=/dev/null &> #{CREW_PREFIX}/var/log/sommelier.log &
          #  echo "$!" > #{CREW_PREFIX}/var/run/sommelier-wayland.pid
          #fi

          if ! checksommelierxwayland; then
            pkill -F #{CREW_PREFIX}/var/run/sommelier-xwayland.pid &>/dev/null
            DISPLAY="${DISPLAY:0:3}"

            xdg_shell_v6=''

            # check if exo support xdg_wm_base
            if [[ -z "$(WAYLAND_DISPLAY=wayland-0 wayland-info -i xdg_wm_base)" ]]; then
              xdg_shell_v6='--xdg-shell-v6'
            fi

            touch ~/.Xauthority
            xauth_cmd="xauth generate ${DISPLAY} . trusted"
            # --enable-xshape Appears to be broken as of Feb 17, 2023.
            sommelier_cmd="sommelier -X \
              --x-display=${DISPLAY} \
              --scale=${SCALE} \
              ${SOMMELIER_DIRECT_SCALE} \
              --glamor \
              --force-drm-device=${SOMMELIER_DRM_DEVICE} \
              --display=wayland-0 \
              --xwayland-path=/usr/local/bin/Xwayland \
              --xwayland-gl-driver-path=#{CREW_LIB_PREFIX}/dri \
              --peer-cmd-prefix=#{CREW_PREFIX}#{@peer_cmd_prefix} \
              --noop-driver ${xdg_shell_v6} \
              --no-exit-with-child \
              /bin/sh -c ${xauth_cmd}"
            echo "$sommelier_cmd" >> #{CREW_PREFIX}/var/log/sommelier.log
            $sommelier_cmd &>> #{CREW_PREFIX}/var/log/sommelier.log &

            pgrep Xwayland > #{CREW_PREFIX}/var/run/sommelier-xwayland.pid
            xhost +si:localuser:root
          fi
        SOMMELIERDEOF

        # startsommelier
        File.write 'startsommelier', <<~STARTSOMMELIEREOF
          #!/bin/bash -a
          # Exit if in container.
          if [[ -f '/.dockerenv' ]]; then
            echo "Cannot run sommelier in a container."
            # Return or exit depending upon whether script was sourced.
            (return 0 2>/dev/null) && return 0 || exit 0
          fi
          mkdir -p #{CREW_PREFIX}/var/log && touch #{CREW_PREFIX}/var/log/sommelier.log
          set -a
          # Set DRM device here so output is visible, but don't run
          # some of these checks in an env.d file since we don't need
          # them run every time a shell is opened.
          # Get a list of all available DRM render nodes.
          DRM_DEVICES_LIST=($(cd /dev/dri/ || exit ; ls renderD*))

          # if two or more render nodes available, choose one based on the corresponding render device path:
          #   devices/platform/vegm/...: virtual GEM device provided by Chrome OS, hardware acceleration may not available on this node. (should be avoided)
          #   devices/pci*/...: linked to the actual graphics card device path, provided by graphics card driver. (preferred)
          #
          if [[ "${#DRM_DEVICES_LIST[@]}" -gt 1 ]]; then
            for dev in "${DRM_DEVICES_LIST[@]}"; do
              if [[ "$(coreutils --coreutils-prog=readlink -f "/sys/class/drm/${dev}/device/driver")" =~ (bus/pci|drm) ]]; then
                SOMMELIER_DRM_DEVICE="/dev/dri/${dev##*/}"
                echo -e "\e[1;33m""${#DRM_DEVICES_LIST[@]} DRM render nodes available, ${SOMMELIER_DRM_DEVICE} will be used.""\e[0m"
                break
              fi
            done
          else
            # if only one node available, use it directly
            SOMMELIER_DRM_DEVICE="/dev/dri/${DRM_DEVICES_LIST[0]##*/}"
          fi
          direct_scaling_possible() {
            # Check if milestone is greater than 105.
            milestone=$(grep CHROMEOS_RELEASE_CHROME_MILESTONE /etc/lsb-release | cut -d= -f2)
            (( $milestone > 105 )) && return 0
            return 1
          }
          # Not sure which milestone enables direct scale, so be
          # conservative.
          SOMMELIER_DIRECT_SCALE=
          if direct_scaling_possible; then
            echo -e "\e[1;33m""Sommelier can use direct scaling.""\e[0m"
            SOMMELIER_DIRECT_SCALE='--direct-scale'
          fi
          set +a
          checksommelierwayland () {
            #if [ -f "#{CREW_PREFIX}/var/run/sommelier-wayland.pid" ]; then
            #  /sbin/ss --unix -a -p |\
            #    grep "\b$(cat #{CREW_PREFIX}/var/run/sommelier-wayland.pid)" |\
            #    grep wayland &>/dev/null
            #else
            #  return 1
            #fi
            # Return or exit depending upon whether script was sourced.
            (return 0 2>/dev/null) && return 0 || exit 0
          }
          checksommelierxwayland () {
            DISPLAY="${DISPLAY}" timeout 1s xset q &>> #{CREW_PREFIX}/var/log/sommelier.log
          }
          if ! checksommelierwayland || ! checksommelierxwayland ; then
            [ -f  #{CREW_PREFIX}/bin/stopbroadway ] && stopbroadway
            set -a
            # via https://stackoverflow.com/questions/47027323/round-to-the-nearest-0-5-decimal-in-bash/47027557#47027557
            function roundhalves {
                    echo "$1 * 2" | bc | xargs -I@ printf "%1.f" @ | xargs -I% echo "% * .5" | bc
            }
            pxwidth=$(WAYLAND_DISPLAY=wayland-0 wayland-info -i wl_output | grep width: | grep px | head -n 1 | awk '{print $2}')
            lwidth=$(WAYLAND_DISPLAY=wayland-0 wayland-info -i zxdg_output_manager_v1 | grep logical_width:  | sed 's/,//' | awk '{print $2}')
            # echo "pxwidth: $pxwidth, lwidth: $lwidth"
            # SCALE needs to be rounded to the nearest 0.5
            # Check to see if pxwidth and lwidth are integers before calculating SCALE.
            # wayland-info on armv7l does not show lwidth, but aarch64 does.
            if [[ $pxwidth == ?(-)+([0-9]) ]] && [[ $lwidth == ?(-)+([0-9]) ]] && [[ -z "$SCALE" ]] ; then
              SCALE=$(roundhalves $(echo "scale=2 ;$lwidth / $pxwidth" | bc))
            fi
            # Set default SCALE to 1 if unset.
            SCALE=${SCALE:-1}
            # Allow overriding environment variables before starting sommelier daemon.
            [ -f "#{CREW_PREFIX}/.config/.sommelier.env" ] && source #{CREW_PREFIX}/.config/.sommelier.env 2>> #{CREW_PREFIX}/var/log/sommelier.log
            set +a
            echo -e "\e[1;33m""Sommelier SCALE is set to \e[1;32m"${SCALE}"\e[1;33m"."\e[0m"
            echo -e "\e[1;33m""SCALE may be manually set in #{CREW_PREFIX}/.config/.sommelier.env .""\e[0m"
            #{CREW_PREFIX}/sbin/sommelierd &>/dev/null &
          fi
          wait=3
          until checksommelierwayland && checksommelierxwayland; do
            [ "${wait}" -le "0" ] && break
            (( wait = wait - 1 ))
            sleep 3
          done

          SOMMWPIDS="$(pgrep -f "sommelier.elf --parent" 2> /dev/null)"
          SOMMWPROCS="$(pgrep -fa "sommelier.elf --parent" 2> /dev/null)"
          SOMMXPIDS="$(pgrep -f "sommelier.elf -X" 2> /dev/null)"
          SOMMXPROCS="$(pgrep -fa "sommelier.elf -X" 2> /dev/null)"

          if checksommelierwayland && checksommelierxwayland ; then
            echo -e "sommelier processes running: ${SOMMWPIDS} ${SOMMXPIDS}"
          else
            echo "some sommelier processes failed to start"
            [[ -n ${SOMMWPROCS} || -n ${SOMMXPROCS} ]] && echo -e "sommelier processes running: ${SOMMWPROCS} \\n ${SOMMXPROCS}"
            # Return or exit depending upon whether script was sourced.
            (return 0 2>/dev/null) && return 1 || exit 1
          fi
        STARTSOMMELIEREOF

        # stopsommelier
        File.write 'stopsommelier', <<~STOPSOMMELIEREOF
          #!/bin/bash
          mkdir -p #{CREW_PREFIX}/var/log && touch #{CREW_PREFIX}/var/log/sommelier.log
          # Quickest way is to use killall on Xwayland
          pgrep Xwayland &>> #{CREW_PREFIX}/var/log/sommelier.log && killall Xwayland
          SOMM="$(pgrep -fc sommelier.elf 2> /dev/null)"
          if [[ "${SOMM}" -gt "0" ]]; then
            pkill -f sommelier.elf &>> #{CREW_PREFIX}/var/log/sommelier.log
            pkill -F #{CREW_PREFIX}/var/run/sommelier-wayland.pid &>> #{CREW_PREFIX}/var/log/sommelier.log
            pkill -F #{CREW_PREFIX}/var/run/sommelier-xwayland.pid &>> #{CREW_PREFIX}/var/log/sommelier.log
          else
            # Return or exit depending upon whether script was sourced.
            (return 0 2>/dev/null) && return 0 || exit 0
          fi
          if [[ "$(pgrep -fc sommelier.elf 2> /dev/null)" -gt "0" ]]; then
            echo "sommelier failed to stop"
            # Return or exit depending upon whether script was sourced.
            (return 0 2>/dev/null) && return 1 || exit 1
          else
            echo "sommelier stopped"
          fi
        STOPSOMMELIEREOF

        # restartsommelier
        File.write 'restartsommelier', <<~RESTARTSOMMELIEREOF
          #!/bin/bash
          stopsommelier && startsommelier
        RESTARTSOMMELIEREOF

        # start sommelier from bash.d, which loads after all of env.d via #{CREW_PREFIX}/etc/profile
        File.write 'bash.d_sommelier', <<~BASHDSOMMELIEREOF
          if [ ! -f '/.dockerenv' ]; then
            source #{CREW_PREFIX}/bin/startsommelier
            mkdir -p #{CREW_PREFIX}/var/log && touch #{CREW_PREFIX}/var/log/sommelier.log
            pgrep Xwayland &>> #{CREW_PREFIX}/var/log/sommelier.log && #{CREW_PREFIX}/etc/sommelierrc &>> #{CREW_PREFIX}/var/log/sommelier.log
          fi
        BASHDSOMMELIEREOF
      end
    end
  end

  def self.install
    FileUtils.mkdir_p %W[#{CREW_DEST_PREFIX}/bin #{CREW_DEST_PREFIX}/sbin #{CREW_DEST_PREFIX}/etc/bash.d
                         #{CREW_DEST_PREFIX}/etc/env.d CREW_DEST_HOME]
    Dir.chdir('vm_tools/sommelier') do
      system "DESTDIR=#{CREW_DEST_DIR} #{CREW_NINJA} -C builddir install"
      Dir.chdir('builddir') do
        FileUtils.mv "#{CREW_DEST_PREFIX}/bin/sommelier", "#{CREW_DEST_PREFIX}/bin/sommelier.elf"
        FileUtils.install 'sommelier_sh', "#{CREW_DEST_PREFIX}/bin/sommelier", mode: 0o755
        FileUtils.install 'sommelierd', "#{CREW_DEST_PREFIX}/sbin/sommelierd", mode: 0o755
        FileUtils.install 'startsommelier', "#{CREW_DEST_PREFIX}/bin/startsommelier", mode: 0o755
        FileUtils.ln_sf 'startsommelier', "#{CREW_DEST_PREFIX}/bin/initsommelier"
        FileUtils.install 'stopsommelier', "#{CREW_DEST_PREFIX}/bin/stopsommelier", mode: 0o755
        FileUtils.install 'restartsommelier', "#{CREW_DEST_PREFIX}/bin/restartsommelier", mode: 0o755
        FileUtils.install 'sommelierrc', "#{CREW_DEST_PREFIX}/etc/sommelierrc", mode: 0o755
        FileUtils.install 'sommelierenv', "#{CREW_DEST_PREFIX}/etc/env.d/sommelier", mode: 0o644
        FileUtils.install 'bash.d_sommelier', "#{CREW_DEST_PREFIX}/etc/bash.d/sommelier", mode: 0o644
      end
    end
  end

  def self.postinstall
    # all tasks are done by #{CREW_PREFIX}/.config/sommelier.env now
    @now = Time.now.strftime('%Y%m%d%H%M')
    FileUtils.cp "#{HOME}/.bashrc", "#{HOME}/.bashrc.#{@now}"
    system "sed -i '/[sS]ommelier/d' #{HOME}/.bashrc"

    if FileUtils.identical?("#{HOME}/.bashrc", "#{HOME}/.bashrc.#{@now}")
      FileUtils.rm "#{HOME}/.bashrc.#{@now}"
    else
      ExitMessage.add <<~EOT0.lightblue

        Removed old sommelier environment variables in: ~/.bashrc
        A backup of the original is stored in: ~/.bashrc.#{@now}
      EOT0
    end

    unless File.exist? "#{CREW_PREFIX}/.config/.sommelier.env"
      FileUtils.mkdir_p "#{CREW_PREFIX}/.config"
      if File.exist? "#{HOME}/.sommelier.env"
        FileUtils.cp "#{HOME}/.sommelier.env", "#{CREW_PREFIX}/.config/.sommelier.env"
        ExitMessage.add <<~EOT0.lightblue

          Overrides of the default sommelier configuration must now be stored in:
          #{CREW_PREFIX}/.config/.sommelier.env
        EOT0
      else
        FileUtils.touch "#{CREW_PREFIX}/.config/.sommelier.env"
      end
    end

    ExitMessage.add <<~EOT1.lightblue

      The default sommelier configuration is stored in: #{CREW_PREFIX}/etc/env.d/sommelier
      DO NOT EDIT THIS FILE SINCE UPDATES WILL OVERWRITE YOUR CHANGES.
      To override the default sommelier configuration, edit: #{CREW_PREFIX}/.config/.sommelier.env
      Information about the sommelier configuration environment variables may be found on the
      Chromebrew wiki: https://github.com/chromebrew/chromebrew/wiki

      To start the sommelier daemon, run 'startsommelier'
      To stop the sommelier daemon, run 'stopsommelier'
      To restart the sommelier daemon, run 'restartsommelier'
    EOT1
    ExitMessage.add <<~EOT2.orange
      Please be aware that gui applications may not work without the
      sommelier daemon running.

      The sommelier daemon may also have to be restarted with
      'restartsommelier' after waking your device.

      (If you are upgrading from an earlier version of sommelier,
      also run 'restartsommelier'.)

      Please open a github issue at
      https://github.com/chromebrew/chromebrew/issues/new/choose
      with the output of
       readlink -f '/sys/class/drm/renderD129/device/driver'
      and
       readlink -f '/sys/class/drm/renderD128/device/driver'
      and
       tail #{CREW_PREFIX}/var/log/sommelier.log
      if sommelier does not start properly on your ChromeOS device.
    EOT2
  end
end
