#!/bin/bash
##### -*- mode:shell-script; indent-tabs-mode:nil; sh-basic-offset:2 -*-
##### Author: Travis Cross <tc@traviscross.com>

mod_dir="../src/mod"
conf_dir="../conf"
lang_dir="../conf/vanilla/lang"
fs_description="FreeSWITCH is a scalable open source cross-platform telephony platform designed to route and interconnect popular communication protocols using audio, video, text or any other form of media."
mod_build_depends="." mod_depends="." mod_recommends="." mod_suggests="."
supported_distros="squeeze wheezy jessie sid"
avoid_mods=(
  applications/mod_limit
  applications/mod_mongo
  applications/mod_mp4
  applications/mod_osp
  applications/mod_rad_auth
  applications/mod_skel
  asr_tts/mod_cepstral
  codecs/mod_com_g729
  codecs/mod_ilbc
  codecs/mod_sangoma_codec
  codecs/mod_siren
  codecs/mod_skel_codec
  endpoints/mod_gsmopen
  endpoints/mod_h323
  endpoints/mod_khomp
  endpoints/mod_opal
  endpoints/mod_reference
  endpoints/mod_unicall
  languages/mod_managed
  languages/mod_perl
  sdk/autotools
  xml_int/mod_xml_ldap
  xml_int/mod_xml_radius
)
avoid_mods_sid=(
  languages/mod_java
)
avoid_mods_jessie=(
)
avoid_mods_wheezy=(
)
avoid_mods_squeeze=(
  formats/mod_vlc
  languages/mod_managed
)
manual_pkgs=(
kazoo-freeswitch
)

err () {
  echo "$0 error: $1" >&2
  exit 1
}

xread () {
  local xIFS="$IFS"
  IFS=''
  read $@
  local ret=$?
  IFS="$xIFS"
  return $ret
}

intersperse () {
  local sep="$1"
  awk "
    BEGIN {
      first=1;
      sep=\"${sep}\";
    }"'
    /.*/ {
      if (first == 0) {
        printf "%s%s", sep, $0;
      } else {
        printf "%s", $0;
      }
      first=0;
    }
    END { printf "\n"; }'
}

postfix () {
  local px="$1"
  awk "
    BEGIN { px=\"${px}\"; }"'
    /.*/ { printf "%s%s\n", $0, px; }'
}

avoid_mod_filter () {
  local x="avoid_mods_$codename[@]"
  local -a mods=("${avoid_mods[@]}" "${!x}")
  for x in "${mods[@]}"; do
    if [ "$1" = "$x" ]; then
      [ "$2" = "show" ] && echo "excluding module $x" >&2
      return 1
    fi
  done
  return 0
}

modconf_filter () {
  while xread l; do
    if [ "$1" = "$l" ]; then
      [ "$2" = "show" ] && echo "including module $l" >&2
      return 0
    fi
  done < modules.conf
  return 1
}

mod_filter () {
  if test -f modules.conf; then
    modconf_filter $@
  else
    avoid_mod_filter $@
  fi
}

mod_filter_show () {
  mod_filter "$1" show
}

map_fs_modules () {
  local filterfn="$1" percatfns="$2" permodfns="$3"
  for x in $mod_dir/*; do
    test -d $x || continue
    test ! ${x##*/} = legacy || continue
    category=${x##*/} category_path=$x
    for f in $percatfns; do $f; done
    for y in $x/*; do
      module_name=${y##*/} module_path=$y
      module=$category/$module_name
      if $filterfn $category/$module; then
        [ -f ${y}/module ] && . ${y}/module
        for f in $permodfns; do $f; done
      fi
      unset module_name module_path module
    done
    unset category category_path
  done
}

map_modules () {
  local filterfn="$1" percatfns="$2" permodfns="$3"
  for x in $parse_dir/*; do
    test -d $x || continue
    category=${x##*/} category_path=$x
    for f in $percatfns; do $f; done
    for y in $x/*; do
      test -f $y || continue
      module=${y##*/} module_path=$y
      $filterfn $category/$module || continue
      module="" category="" module_name=""
      section="" description="" long_description=""
      build_depends="" depends="" recommends="" suggests=""
      distro_conflicts=""
      distro_vars=""
      for x in $supported_distros; do
        distro_vars="$distro_vars build_depends_$x"
        eval build_depends_$x=""
      done
      . $y
      [ -n "$description" ] || description="$module_name"
      [ -n "$long_description" ] || description="Adds ${module_name}."
      for f in $permodfns; do $f; done
      unset \
        module module_name module_path \
        section description long_description \
        build_depends depends recommends suggests \
        distro_conflicts $distro_vars
    done
    unset category category_path
  done
}

map_confs () {
  local fs="$1"
  for x in $conf_dir/*; do
    test ! -d $x && continue
    conf=${x##*/} conf_dir=$x
    for f in $fs; do $f; done
    unset conf conf_dir
  done
}

map_langs () {
  local fs="$1"
  for x in $lang_dir/*; do
    test ! -d $x && continue
    lang=${x##*/} lang_dir=$x
    for f in $fs; do $f; done
    unset lang lang_dir
  done
}

map_pkgs () {
  local fsx="$1"
  for x in "${manual_pkgs[@]}"; do
    $fsx $x
  done
  map_pkgs_confs () { $fsx "freeswitch-conf-${conf//_/-}"; }
  map_confs map_pkgs_confs
  map_pkgs_langs () { $fsx "freeswitch-lang-${lang//_/-}"; }
  map_langs map_pkgs_langs
  map_pkgs_mods () {
    $fsx "freeswitch-${module//_/-}"
    $fsx "freeswitch-${module//_/-}-dbg"; }
  map_modules map_pkgs_mods
}

list_pkgs () {
  list_pkgs_thunk () { printf '%s\n' "$1"; }
  map_pkgs list_pkgs_thunk
}

list_freeswitch_all_pkgs () {
  list_pkgs \
    | grep -v '^freeswitch-all$' \
    | grep -v -- '-dbg$'
}

list_freeswitch_all_provides () {
  list_freeswitch_all_pkgs \
    | intersperse ',\n '
}

list_freeswitch_all_replaces () {
  list_freeswitch_all_pkgs \
    | postfix ' (<= ${binary:Version})' \
    | intersperse ',\n '
}

list_freeswitch_all_dbg_pkgs () {
  list_pkgs \
    | grep -v '^freeswitch-all-dbg$' \
    | grep -- '-dbg$'
}

list_freeswitch_all_dbg_provides () {
  list_freeswitch_all_dbg_pkgs \
    | intersperse ',\n '
}

list_freeswitch_all_dbg_replaces () {
  list_freeswitch_all_dbg_pkgs \
    | postfix ' (<= ${binary:Version})' \
    | intersperse ',\n '
}

print_source_control () {
cat <<EOF
Source: kazoo-freeswitch
Section: comm
Priority: optional
Maintainer: Travis Cross <tc@traviscross.com>
Build-Depends:
# for debian
 debhelper (>= 8.0.0),
# bootstrapping
 automake (>= 1.9), autoconf, libtool,
# core build
 dpkg-dev (>= 1.15.8.12), gcc (>= 4:4.4.5), g++ (>= 4:4.4.5),
 libc6-dev (>= 2.11.3), make (>= 3.81),
 libpcre3-dev,
 libedit-dev (>= 2.11),
 libsqlite3-dev,
 wget, pkg-config,
# core codecs
 libogg-dev, libspeex-dev, libspeexdsp-dev,
# configure options
 libssl-dev, unixodbc-dev, libpq-dev,
 libncurses5-dev, libjpeg62-dev | libjpeg8-dev,
 python-dev, erlang-dev,
# documentation
 doxygen,
# for APR (not essential for build)
 uuid-dev, libexpat1-dev, libgdbm-dev, libdb-dev,
# used by many modules
 libcurl4-openssl-dev | libcurl4-gnutls-dev | libcurl-dev,
 bison, zlib1g-dev,
# module build-depends
 $(debian_wrap "${mod_build_depends}")
Standards-Version: 3.9.3
Homepage: http://freeswitch.org/
Vcs-Git: git://git.freeswitch.org/freeswitch
Vcs-Browser: http://git.freeswitch.org/git/freeswitch/

EOF
}

print_core_control () {
cat <<EOF
Package: kazoo-freeswitch
Architecture: any
Provides: kazoo-freeswitch 
Replaces: 
Conflicts: 
Depends: 
 kazoo-prompts (>= 1.0.8),
 kazoo-configs-freeswitch (>= 3.0.0),
 esl-erlang (>= 1:15.b.3),
 .
Description: Cross-Platform Scalable Multi-Protocol Soft Switch
 FreeSWITCH is a scalable open source cross-platform telephony
 platform designed to route and interconnect popular communication
 protocols using audio, video, text or any other form of media.
 .
 This package contains FreeSWITCH and all modules and extras.


EOF
}

print_mod_control () {
  local m_section="${section:-comm}"
  cat <<EOF
Package: freeswitch-${module_name//_/-}
Section: ${m_section}
Architecture: any
$(debian_wrap "Depends: \${shlibs:Depends}, \${misc:Depends}, libfreeswitch1 (= \${binary:Version}), ${depends}")
$(debian_wrap "Recommends: ${recommends}")
$(debian_wrap "Suggests: freeswitch-${module_name//_/-}-dbg, ${suggests}")
Description: ${description} for FreeSWITCH
 $(debian_wrap "${fs_description}")
 .
 $(debian_wrap "This package contains ${module_name} for FreeSWITCH.")
 .
 $(debian_wrap "${long_description}")

Package: freeswitch-${module_name//_/-}-dbg
Section: debug
Priority: extra
Architecture: any
Depends: \${misc:Depends},
 freeswitch-${module_name//_/-} (= \${binary:Version})
Description: ${description} for FreeSWITCH (debug)
 $(debian_wrap "${fs_description}")
 .
 $(debian_wrap "This package contains debugging symbols for ${module_name} for FreeSWITCH.")
 .
 $(debian_wrap "${long_description}")

EOF
}

print_mod_install () {
  cat <<EOF
/usr/lib/freeswitch/mod/${1}.so
EOF
}

print_long_filename_override () {
  local p="$1"
  cat <<EOF
# The long file names are caused by appending the nightly information.
# Since one of these packages will never end up on a Debian CD, the
# related problems with long file names will never come up here.
${p}: package-has-long-file-name *

EOF
}

print_gpl_openssl_override () {
  local p="$1"
  cat <<EOF
# We're definitely not doing this.  Nothing in FreeSWITCH has a more
# restrictive license than LGPL or MPL.
${p}: possible-gpl-code-linked-with-openssl

EOF
}

print_itp_override () {
  local p="$1"
  cat <<EOF
# We're not in Debian (yet) so we don't have an ITP bug to close.
${p}: new-package-should-close-itp-bug

EOF
}

print_common_overrides () {
  print_long_filename_override "$1"
}

print_mod_overrides () {
  print_common_overrides "$1"
  print_gpl_openssl_override "$1"
}

print_conf_overrides () {
  print_common_overrides "$1"
}

print_conf_control () {
  cat <<EOF
Package: freeswitch-conf-${conf//_/-}
Architecture: all
Depends: \${misc:Depends}
Description: FreeSWITCH ${conf} configuration
 $(debian_wrap "${fs_description}")
 .
 $(debian_wrap "This package contains the ${conf} configuration for FreeSWITCH.")

EOF
}

print_conf_install () {
  cat <<EOF
conf/${conf} /usr/share/freeswitch/conf
EOF
}

print_lang_overrides () {
  print_common_overrides "$1"
}

print_lang_control () {
  local lang_name="$(echo ${lang} | tr '[:lower:]' '[:upper:]')"
  case "${lang}" in
    de) lang_name="German" ;;
    en) lang_name="English" ;;
    es) lang_name="Spanish" ;;
    fr) lang_name="French" ;;
    he) lang_name="Hebrew" ;;
    pt) lang_name="Portuguese" ;;
    ru) lang_name="Russian" ;;
  esac
  cat <<EOF
Package: freeswitch-lang-${lang//_/-}
Architecture: all
Depends: \${misc:Depends}
Recommends: freeswitch-sounds-${lang}
Description: ${lang_name} language files for FreeSWITCH
 $(debian_wrap "${fs_description}")
 .
 $(debian_wrap "This package includes the ${lang_name} language files for FreeSWITCH.")

EOF
}

print_lang_install () {
  cat <<EOF
conf/vanilla/lang/${lang} /usr/share/freeswitch/lang
EOF
}

print_edit_warning () {
  echo "#### Do not edit!  This file is auto-generated from debian/bootstrap.sh."; echo
}

gencontrol_per_mod () {
  print_mod_control "$module_name" "$description" "$long_description" >> control
}

gencontrol_per_cat () {
  (echo "## mod/$category"; echo) >> control
}

geninstall_per_mod () {
  local f=freeswitch-${module_name//_/-}.install
  (print_edit_warning; print_mod_install "$module_name") > $f
  print_mod_install "$module_name" >> freeswitch-all.install
  test -f $f.tmpl && cat $f.tmpl >> $f
}

genoverrides_per_mod () {
  local f=freeswitch-${module_name//_/-}.lintian-overrides
  (print_edit_warning; print_mod_overrides freeswitch-${module_name//_/-}) > $f
  test -f $f.tmpl && cat $f.tmpl >> $f
}

genmodulesconf () {
  genmodules_per_cat () { echo "## $category"; }
  genmodules_per_mod () { echo "$module"; }
  print_edit_warning
  map_modules 'mod_filter' 'genmodules_per_cat' 'genmodules_per_mod'
}

genconf () {
  print_conf_control >> control
  local p=freeswitch-conf-${conf//_/-}
  local f=$p.install
  (print_edit_warning; print_conf_install) > $f
  print_conf_install >> freeswitch-all.install
  test -f $f.tmpl && cat $f.tmpl >> $f
  local f=$p.lintian-overrides
  (print_edit_warning; print_conf_overrides "$p") > $f
  test -f $f.tmpl && cat $f.tmpl >> $f
}

genlang () {
  print_lang_control >> control
  local p=freeswitch-lang-${lang//_/-}
  local f=$p.install
  (print_edit_warning; print_lang_install) > $f
  print_lang_install >> freeswitch-all.install
  test -f $f.tmpl && cat $f.tmpl >> $f
  local f=$p.lintian-overrides
  (print_edit_warning; print_lang_overrides "$p") > $f
  test -f $f.tmpl && cat $f.tmpl >> $f
}

accumulate_mod_deps () {
  local x=""
  # build-depends
  if [ -n "$(eval echo \$build_depends_$codename)" ]; then
    x="$(eval echo \$build_depends_$codename)"
  else x="${build_depends}"; fi
  if [ -n "$x" ]; then
    if [ ! "$mod_build_depends" = "." ]; then
      mod_build_depends="${mod_build_depends}, ${x}"
    else mod_build_depends="${x}"; fi; fi
  # depends
  if [ -n "$(eval echo \$depends_$codename)" ]; then
    x="$(eval echo \$depends_$codename)"
  else x="${depends}"; fi
  x="$(echo "$x" | sed 's/, \?/\n/g' | grep -v '^freeswitch' | tr '\n' ',' | sed -e 's/,$//' -e 's/,/, /g')"
  if [ -n "$x" ]; then
    if [ ! "$mod_depends" = "." ]; then
      mod_depends="${mod_depends}, ${x}"
    else mod_depends="${x}"; fi; fi
  # recommends
  if [ -n "$(eval echo \$recommends_$codename)" ]; then
    x="$(eval echo \$recommends_$codename)"
  else x="${recommends}"; fi
  x="$(echo "$x" | sed 's/, \?/\n/g' | grep -v '^freeswitch' | tr '\n' ',' | sed -e 's/,$//' -e 's/,/, /g')"
  if [ -n "$x" ]; then
    if [ ! "$mod_recommends" = "." ]; then
      mod_recommends="${mod_recommends}, ${x}"
    else mod_recommends="${x}"; fi; fi
  # suggests
  if [ -n "$(eval echo \$suggests_$codename)" ]; then
    x="$(eval echo \$suggests_$codename)"
  else x="${suggests}"; fi
  x="$(echo "$x" | sed 's/, \?/\n/g' | grep -v '^freeswitch' | tr '\n' ',' | sed -e 's/,$//' -e 's/,/, /g')"
  if [ -n "$x" ]; then
    if [ ! "$mod_suggests" = "." ]; then
      mod_suggests="${mod_suggests}, ${x}"
    else mod_suggests="${x}"; fi; fi
}

genmodctl_new_mod () {
  grep -e "^Module: ${module}$" control-modules >/dev/null && return 0
  cat <<EOF
Module: $module
Description: $description
 $long_description
EOF
  echo
}

genmodctl_new_cat () {
  grep -e "^## mod/${category}$" control-modules >/dev/null && return 0
  cat <<EOF
## mod/$category

EOF
}

pre_parse_mod_control () {
  local fl=true ll_nl=false ll_descr=false
  while xread l; do
    if [ -z "$l" ]; then
      # is newline
      if ! $ll_nl && ! $fl; then
        echo
      fi
      ll_nl=true
      continue
    elif [ -z "${l##\#*}" ]; then
      # is comment
      continue
    elif [ -z "${l## *}" ]; then
      # is continuation line
      if ! $ll_descr; then
        echo -n "$l"
      else
        echo -n "Long-Description: $(echo "$l" | sed -e 's/^ *//')"
      fi
    else
      # is header line
      $fl || echo
      if [ "${l%%:*}" = "Description" ]; then
        ll_descr=true
        echo "Description: ${l#*: }"
        continue
      else
        echo -n "$l"
      fi
    fi
    fl=false ll_nl=false ll_descr=false
  done < control-modules
}

var_escape () {
  (echo -n \'; echo -n "$1" | sed -e "s/'/'\\\\''/g"; echo -n \')
}

parse_mod_control () {
  pre_parse_mod_control > control-modules.preparse
  local category=""
  local module_name=""
  rm -rf $parse_dir
  while xread l; do
    if [ -z "$l" ]; then
      # is newline
      continue
    fi
    local header="${l%%:*}"
    local value="${l#*: }"
    if [ "$header" = "Module" ]; then
      category="${value%%/*}"
      module_name="${value#*/}"
      mkdir -p $parse_dir/$category
      (echo "module=$(var_escape "$value")"; \
        echo "category=$(var_escape "$category")"; \
        echo "module_name=$(var_escape "$module_name")"; \
        ) >> $parse_dir/$category/$module_name
    else
      ([ -n "$category" ] && [ -n "$module_name" ]) \
        || err "unexpected header $header"
      local var_name="$(echo "$header" | sed -e 's/-/_/g' | tr '[A-Z]' '[a-z]')"
      echo "${var_name}=$(var_escape "$value")" >> $parse_dir/$category/$module_name
    fi
  done < control-modules.preparse
}

debian_wrap () {
  local fl=true
  echo "$1" | fold -s -w 69 | while xread l; do
    local v="$(echo "$l" | sed -e 's/ *$//g')"
    if $fl; then
      fl=false
      echo "$v"
    else
      echo " $v"
    fi
  done
}

genmodctl_cat () {
  (echo "## mod/$category"; echo)
}

genmodctl_mod () {
  echo "Module: $module"
  [ -n "$section" ] && echo "Section: $section"
  echo "Description: $description"
  echo "$long_description" | fold -s -w 69 | while xread l; do
    local v="$(echo "$l" | sed -e 's/ *$//g')"
    echo " $v"
  done
  [ -n "$build_depends" ] && debian_wrap "Build-Depends: $build_depends"
  for x in $supported_distros; do
    [ -n "$(eval echo \$build_depends_$x)" ] \
      && debian_wrap "Build-Depends-$x: $(eval echo \$build_depends_$x)"
  done
  [ -n "$depends" ] && debian_wrap "Depends: $depends"
  [ -n "$reccomends" ] && debian_wrap "Recommends: $recommends"
  [ -n "$suggests" ] && debian_wrap "Suggests: $suggests"
  [ -n "$distro_conflicts" ] && debian_wrap "Distro-Conflicts: $distro_conflicts"
  echo
}

set_modules_non_dfsg () {
  local len=${#avoid_mods}
  for ((i=0; i<len; i++)); do
    case "${avoid_mods[$i]}" in
      codecs/mod_siren|codecs/mod_ilbc)
        unset avoid_mods[$i]
        ;;
    esac
  done
}

conf_merge () {
  local of="$1" if="$2"
  if [ -s $if ]; then
    grep -v '^##\|^$' $if | while xread x; do
      touch $of
      if ! grep -e "$x" $of >/dev/null; then
        printf '%s\n' "$x" >> $of
      fi
    done
  fi
}

codename="sid"
modulelist_opt=""
while getopts "c:m:" o; do
  case "$o" in
    c) codename="$OPTARG" ;;
    m) modulelist_opt="$OPTARG" ;;
  esac
done
shift $(($OPTIND-1))

echo "Bootstrapping debian/ for ${codename}" >&2
echo >&2
echo "Please wait, this takes a few seconds..." >&2

test -z "$modulelist_opt" || set_modules_${modulelist_opt/-/_}

echo "Adding any new modules to control-modules..." >&2
parse_dir=control-modules.parse
##map_fs_modules ':' 'genmodctl_new_cat' 'genmodctl_new_mod' >> control-modules
echo "Parsing control-modules..." >&2
##parse_mod_control
echo "Displaying includes/excludes..." >&2
##map_modules 'mod_filter_show' '' ''
echo "Generating modules_.conf..." >&2
##genmodulesconf > modules_.conf
echo "Generating control-modules.gen as sanity check..." >&2
(echo "# -*- mode:debian-control -*-"; \
  echo "##### Author: Travis Cross <tc@traviscross.com>"; echo; \
  ###map_modules ':' 'genmodctl_cat' 'genmodctl_mod' \
  ) > control-modules.gen

echo "Accumulating dependencies from modules..." >&2
###map_modules 'mod_filter' '' 'accumulate_mod_deps'
echo "Generating debian/..." >&2
> control
(print_edit_warning; print_source_control; print_core_control) >> control

echo "Generating additional lintian overrides..." >&2
grep -e '^Package:' control | while xread l; do
  m="${l#*: }"
  f=$m.lintian-overrides
  [ -s $f ] || print_edit_warning >> $f
  if ! grep -e 'package-has-long-file-name' $f >/dev/null; then
    print_long_filename_override "$m" >> $f
  fi
  if ! grep -e 'new-package-should-close-itp-bug' $f >/dev/null; then
    print_itp_override "$m" >> $f
  fi
done

echo "Cleaning up..." >&2
rm -f control-modules.preparse
rm -rf control-modules.parse
diff control-modules control-modules.gen >/dev/null && rm -f control-modules.gen

echo "Done bootstrapping debian/" >&2
touch .stamp-bootstrap
