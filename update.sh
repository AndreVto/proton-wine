#!/usr/bin/env bash
set -euo pipefail

if (( $# == 0 )); then
  printf 'Usage: %s all | file [file ...]\n' "$0" >&2
  exit 2
fi

cd "$(git rev-parse --show-toplevel)"
patch_dir=android/patches
mkdir -p "$patch_dir"

is_generated() {
  case "$1" in
    configure|configure.lineno|include/config.h|include/config.h.in|\
    include/wine/server_protocol.h|include/wine/vulkan.h|\
    server/request_handlers.h|server/request_trace.h|\
    dlls/ntdll/ntsyscalls.h|dlls/win32u/win32syscalls.h|\
    dlls/vulkan-1/vulkan-1.spec|\
    dlls/winevulkan/loader_thunks.[ch]|dlls/winevulkan/vulkan_thunks.[ch]|\
    dlls/winevulkan/winevulkan.json|dlls/winevulkan/winevulkan.spec|\
    *.tab.c|*.tab.h|*.yy.c|*.lex.c|*.generated.*|\
    *.patch|*.orig|*.rej|*.bak|*.tmp|*~|*/Makefile|*/config.h)
      return 0 ;;
  esac
  return 1
}

is_source() {
  case "$1" in
    configure.ac|Makefile.in|aclocal.m4.in|dlls/winevulkan/make_vulkan)
      return 0 ;;
    dlls/*|include/*|server/*|loader/*|loader64/*|programs/*|libs/*|tools/*|fonts/*|nls/*|po/*|data/*)
      case "$1" in
        *.c|*.h|*.cc|*.cpp|*.cxx|*.s|*.S|*.in|*.spec|*.def|*.idl|*.rc|*.mc|*.y|*.l|\
        *.m|*.mm|*.ac|*.am|*.py|*.sh|*.pl|*.awk|*.xml|*.json|*.po|*.pot|*.manifest)
          return 0 ;;
      esac ;;
  esac
  return 1
}

if [[ "$1" == all ]]; then
  if (( $# != 1 )); then
    printf 'Use all by itself.\n' >&2
    exit 2
  fi
  mapfile -d '' -t files < <(
    git diff --name-only --no-renames -z HEAD --
    git ls-files --others --exclude-standard -z
  )
else
  files=("$@")
fi

count=0
for file in "${files[@]}"; do
  file=${file#./}
  if is_generated "$file" || ! is_source "$file"; then
    printf 'SKIP %s\n' "$file"
    continue
  fi

  patch="$patch_dir/${file//\//_}.patch"
  tmp=$(mktemp "$patch_dir/.patch.XXXXXX")

  if git ls-files --error-unmatch -- "$file" >/dev/null 2>&1; then
    git diff --binary --no-ext-diff HEAD -- "$file" > "$tmp"
  elif [[ -f "$file" ]]; then
    git diff --no-index --binary -- /dev/null "$file" > "$tmp" || {
      rc=$?
      if (( rc != 1 )); then
        rm -f -- "$tmp"
        exit "$rc"
      fi
    }
  else
    printf 'NOT FOUND %s\n' "$file" >&2
    rm -f -- "$tmp"
    exit 1
  fi

  if [[ ! -s "$tmp" ]]; then
    rm -f -- "$tmp" "$patch"
    printf 'NO DIFF %s\n' "$file"
  elif cmp -s -- "$tmp" "$patch"; then
    rm -f -- "$tmp"
    printf 'UNCHANGED %s\n' "$patch"
  else
    mv -f -- "$tmp" "$patch"
    printf 'UPDATED %s\n' "$patch"
    ((count+=1))
  fi
done

printf 'Updated %d patch(es).\n' "$count"
