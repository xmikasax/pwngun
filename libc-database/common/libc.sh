#!/bin/bash

mkdir -p db

die() {
  echo >&2 $1
  exit 1
}

dump_symbols() {
  readelf -Ws $1 | perl -n -e '/: (\w*).*?(\w+)@@GLIBC_/ && print "$2 $1\n"'
}

extract_label() {
  perl -n -e '/(\w+)/ && print $1'
}

dump_libc_start_main_ret() {
  local call_main=`objdump -D $1 \
    | egrep -A 100 '<__libc_start_main.*>' \
    | grep call \
    | egrep -B 1 '<exit.*>' \
    | head -n 1 \
    | extract_label`
  local offset=`objdump -D $1 | egrep -A 1 "(^| )$call_main:" | tail -n 1 | extract_label`
  if [[ "$offset" != "" ]]; then
    echo "__libc_start_main_ret $offset"
  fi
}

dump_bin_sh() {
  local offset=`strings -a -t x $1 | grep '/bin/sh' | head -n1 | extract_label`
  if [[ "$offset" != "" ]]; then
    echo "str_bin_sh $offset"
  fi
}

process_libc() {
  local libc=$1
  local id=$2
  local info=$3
  local url=$4
  echo "  -> Writing libc to db/${id}.so"
  cp $libc db/${id}.so
  echo "  -> Writing symbols to db/${id}.symbols"
  (dump_symbols $libc; dump_libc_start_main_ret $libc; dump_bin_sh $libc) \
     > db/${id}.symbols
  echo "  -> Writing version info"
  echo "$info" > db/${id}.info
  echo "$url" > db/${id}.url
}

check_id() {
  local id=$1
  if [[ -e db/${id}.info ]]; then
    echo "  -> Already have this version, 'rm db/${id}.*' to force"
    return 1
  fi
  return 0
}

# ===== Ubuntu ===== #

get_ubuntu() {
  local url="$1"
  local info="$2"
  local tmp=`mktemp -d`
  echo "Getting $info"
  echo "  -> Location: $url"
  local id=`echo $url | perl -n -e '/(libc6[^\/]*)\./ && print $1'`
  echo "  -> ID: $id"
  check_id $id || return 0
  echo "  -> Downloading package"
  wget --connect-timeout 30 -t 1 "$url" -O $tmp/pkg.deb 2>/dev/null || return 1
  echo "  -> Extracting package"
  pushd $tmp 1>/dev/null
  ar x pkg.deb || die "ar failed"
  tar xf data.tar.* || die "tar failed"
  popd 1>/dev/null
  suffix=
  cnt=1
  for libc in $(find $tmp -name libc.so.6 || return 1); do
    process_libc $libc $id$suffix $info $url
    cnt=$((cnt+1))
    suffix=_$cnt
  done
  rm -rf $tmp
  return 0
}

get_current_debian_like() {
  local version=$1
  local arch=$2
  local pkg=$3
  local distro=$4
  local website=$5
  local info=$distro-$version-$arch-$pkg
  echo "Getting package $pkg location for $distro-$version-$arch"
  local urls=""
  mirrors_url="$website/$version/$arch/$pkg/download"
  echo $mirrors_url
  for i in $(seq 1 3); do
    urls=`(wget $mirrors_url -O - 2>/dev/null \
           | grep -oh 'http://[^"]*libc6[^"]*.deb')`
    for url in $urls
    do
        get_ubuntu $url $info && return 0
        echo "Failed, trying next url"
    done
    sleep 1
  done
  echo "urls: $urls"
  die "Failed to get package version"
}

get_current_ubuntu() {
  get_current_debian_like "$@" "ubuntu" "http://packages.ubuntu.com"
}

get_all_ubuntu() {
  local info=$1
  local url=$2
  for f in `wget $url/ -O - 2>/dev/null | egrep -oh 'libc6(-i386|-amd64)?_[^"]*(amd64|i386)\.deb' |grep -v "</a>"`; do
    get_ubuntu $url/$f $1
  done
}

# ===== Debian ===== #

get_current_debian() {
  get_current_debian_like "$@" "debian" "https://packages.debian.org"
}

# ===== Local ===== #

add_local() {
  local libc=$1
  [[ -e $libc ]] || return
  local info="local"
  local id="local-`sha1sum $libc`"
  echo "Adding local libc $libc (id $id)"
  check_id $id || return
  process_libc $libc $id $info
}