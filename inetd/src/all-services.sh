#! /bin/bash
# $Id$
# required: pdb-commandline.rpm
#

# See doc/README.maintainer

# generate default_conf_{inet,xinetd}.ycp, as required by
# http://w3.suse.de/~kkaempf/yast2/planning/descr/improvement_24.html
# by
# - querying PDB for all config files
# - extracting them all
# - running the agent (for inetd, xinetd)
# - for each program, quering the PDB which RPM it is in

SX=default_conf

# $1: package name
# $2: file (wildcard) to extract
function extract() {
    echo "$1" >&2
    # rpm3: etc/foo, rpm4: ./etc/foo
    rpm2cpio /work/CDs/all/full-i386/suse/*/$1.rpm \
    | cpio -idm --no-absolute-filenames "./$2" "$2" 2> /dev/null
}

# $1: file name
function add_header() {
    mv "$1" "$1"~
    # do not let CVS or bash expand the keyword
    cat - "$1"~ <<EOF > "$1"
// This file is generated by inetd/src/all-services.sh - DO NOT EDIT! --
// \$Id\$
{
textdomain "inetd";
global services_t default_conf =
EOF
    echo ";}" >> "$1"
}

if [ ! -d etc ]; then
extract xinetd etc/xinetd.conf

# no leading slash
DIR=etc/xinetd.d
pdb query --release stable-i386 --filter "rpmdir:/$DIR" --attribs packname > $SX-pkgs

sort $SX-pkgs | while read pkg; do
    extract $pkg "$DIR/*"
done
fi

# use the current agent
ln -snf ../agents servers_non_y2

echo Proceeding in YCP
Y2DIR=. /sbin/yast2 ${SX}_create.ycp

# appease check_ycp
add_header ${SX}_xinetd.ycp