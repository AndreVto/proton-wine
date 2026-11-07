#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"
cd "$repo_root"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  printf 'ERROR: not inside a Git repository: %s\n' "$repo_root" >&2
  exit 1
fi

patch_dir="$repo_root/android/patches"
patches=(
  "server_protocol.def.patch"
  "configure.ac.patch"
  "dlls_advapi32_advapi.c.patch"
  "dlls_amd_ags_x64_unixlib.c.patch"
  "dlls_kernelbase_memory.c.patch"
  "dlls_mmdevapi_main.c.patch"
  "dlls_dnsapi_libresolv.c.patch"
  "dlls_dnsapi_record.c.patch"
  "dlls_midimap_Makefile.in.patch"
  "dlls_midimap_midimap.c.patch"
  "dlls_nsiproxy.sys_nsi_common.h.patch"
  "dlls_nsiproxy.sys_ip.c.patch"
  "dlls_nsiproxy.sys_ndis.c.patch"
  "dlls_ntdll_Makefile.in.patch"
  "dlls_ntdll_tests_exception.c.patch"
  "dlls_ntdll_unix_fsync.h.patch"
  "dlls_ntdll_unix_process_relay.c.patch"
  "dlls_ntdll_unix_process_relay.h.patch"
  "dlls_ntdll_unix_signal_arm64.c.patch"
  "dlls_ntdll_unix_thread.c.patch"
  "dlls_ntdll_unix_unix_private.h.patch"
  "dlls_ntdll_unix_fsync.c.patch"
  "dlls_ntdll_unix_loader.c.patch"
  "dlls_ntdll_unix_server.c.patch"
  "dlls_ntdll_unix_sync.c.patch"
  "dlls_ntdll_unix_virtual.c.patch"
  "dlls_ntdll_unix_signal_x86_64.c.patch"
  "dlls_opengl32_unix_wgl.c.patch"
  "dlls_user32_Makefile.in.patch"
  "dlls_win32u_clipboard.c.patch"
  "dlls_win32u_opengl.c.patch"
  "dlls_win32u_vulkan.c.patch"
  "dlls_win32u_window.c.patch"
  "dlls_winebus.sys_bus_sdl.c.patch"
  "dlls_winebus.sys_Makefile.in.patch"
  "dlls_winebus.sys_bus_android.c.patch"
  "dlls_winebus.sys_main.c.patch"
  "dlls_winebus.sys_unix_private.h.patch"
  "dlls_winebus.sys_unixlib.c.patch"
  "dlls_winebus.sys_unixlib.h.patch"
  "dlls_winegstreamer_unixlib.c.patch"
  "dlls_wineaaudio.drv_Makefile.in.patch"
  "dlls_wineaaudio.drv_aaudio.c.patch"
  "dlls_wineaaudio.drv_game_audio_capture_shared.h.patch"
  "dlls_winepulse.drv_pulse.c.patch"
  "dlls_winex11.drv_bitblt.c.patch"
  "dlls_winex11.drv_keyboard.c.patch"
  "dlls_winex11.drv_mouse.c.patch"
  "dlls_winex11.drv_opengl.c.patch"
  "dlls_winex11.drv_vulkan.c.patch"
  "dlls_winex11.drv_window.c.patch"
  "dlls_winex11.drv_x11drv.h.patch"
  "dlls_winex11.drv_x11drv_main.c.patch"
  "dlls_wow64_syscall.c.patch"
  "include_wine_gdi_driver.h.patch"
  "include_wine_unixlib.h.patch"
  "include_winternl.h.patch"
  "loader_preloader.c.patch"
  "loader64_Makefile.in.patch"
  "loader_Makefile.in.patch"
  "loader_main.c.patch"
  "loader_process_relay.c.patch"
  "loader_process_relay.h.patch"
  "programs_explorer_desktop.c.patch"
  "programs_wineboot_wineboot.c.patch"
  "programs_winebrowser_Makefile.in.patch"
  "programs_winebrowser_main.c.patch"
  "programs_winemenubuilder_winemenubuilder.c.patch"
  "server_Makefile.in.patch"
  "server_fsync.c.patch"
  "server_fsync.h.patch"
  "server_inproc_sync.c.patch"
  "server_main.c.patch"
  "server_thread.c.patch"
  "server_unicode.c.patch"
  "dlls_ntdll_unix_esync.c.patch"
  "dlls_ntdll_unix_esync.h.patch"
  "server_esync.c.patch"
  "server_esync.h.patch"
)

for patch in "${patches[@]}"; do
  if [[ ! -f "$patch_dir/$patch" ]]; then
    printf 'ERROR: missing patch: %s\n' "$patch_dir/$patch" >&2
    exit 1
  fi
done

applied=0
already_applied=0

for patch in "${patches[@]}"; do
  path="$patch_dir/$patch"

  if git apply --check -- "$path" 2>/dev/null; then
    git apply -- "$path"
    printf 'APPLIED: %s\n' "$patch"
    ((applied+=1))
  elif git apply --reverse --check -- "$path" 2>/dev/null; then
    printf 'ALREADY APPLIED: %s\n' "$patch"
    ((already_applied+=1))
  else
    printf 'FAILED: %s\n' "$patch" >&2
    git apply --check -- "$path" >&2 || true
    exit 1
  fi
done

printf 'Patch application complete: %d applied, %d already applied.\n' "$applied" "$already_applied"
