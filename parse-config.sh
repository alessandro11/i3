#!/usr/bin/env bash

#set -x

I3_CONFIG_FILE="/tmp/i3.conf"
I3_CONF_DIR="$HOME/.i3"
outputs=''
theme=''

err() {
    echo $@ 1>&2
}

bar_color_theme() {
    local theme=$1
    local output_conf=$2
    local block_color_theme=''

    block_color_theme=$(grep -E -A 8 'colors[ ]+\\\{' color-theme-${theme}.conf)
    sed "/#import COLOR-THEME/a $block_color_theme" $output_conf >> $I3_CONFIG_FILE
}

wm_color_theme() {
    local theme=$1
    local block_color_theme=''

    block_color_theme=$(grep -E '^client.*' color-theme-${theme}.conf)
    echo "$block_color_theme" >> $I3_CONFIG_FILE
}

get_output_conf() {
    local outputs=$1 conf='' ret=0
    declare -g -a combinations=()

    while read -d',' out; do
        combinations+=("$out")
    done < <(echo "$outputs")

    IFS_BK=$IFS
    IFS='-'
    conf="${combinations[*]}.conf"
    IFS=$IFS_BK
    if [ ! -f "$conf" ]; then
        ret=1
    fi

    echo "$conf"
    return $ret
}

help() {
    echo -e "Usage: $(basename $0)"
    echo -e "\t[-t <color theme>] empty, solarized is assumed"
    echo -e "\t\t *** NOT IMPLEMENTED ***"
    echo -e "\t\t at the moment is static, returns eDP1.conf"
    echo -e "\t[-o <video outpu(s)>] empty, eDP1 is assumed; e.g.: eDP1,DP1,DP2;"
    echo -e "\ta file with one of those combinations must exist:"
    echo -e "\teDP1-DP1-DP2.conf, DP1-eDP1-DP2.conf, DP1-DP2-eDP1.conf,"
    echo -e "\tDP2-DP1-eDP1.conf, DP2-eDP1-DP1.conf"
}

#
# parse-config.sh
#   -t: color theme; expect the block 'colors {...' with 8 lines
#       see color-theme-solarized.conf for example.
#       it will be concatenated color-theme-"solarized".conf
#
#   -o: video output; outputs with separated comma. (e.g; DP1,eDP1)
#       it will make all possible combinations with the order of outputs
#       until find a file with such conf, the example above would result:
#       DP1-eDP1.conf -> eDP1-DP1.conf what ever could be found first
#
# parse-config.sh -t solarized -o eDP!,DP1
#
while getopts ":t:o:h" opt; do
    case $opt in
        t)
            theme=$OPTARG
            ;;
        o)
            outputs=$OPTARG
            ;;
        h)
            help
            exit 0
            ;;
        \?)
            err "Invalid option -$OPTARG"
            exit 1
    esac
done

theme=${theme:-solarized}
outputs=${outputs:-eDP1,}
# Get output video file (e.g.: eDP1.conf)
output_conf=$(get_output_conf $outputs)
if [ $? -ne 0 ]; then
    err "'$output_conf' not found!"
    exit $?
fi

# Generte common settings: key binds etc.
cat common.conf > "$I3_CONFIG_FILE"

# get status bar theme
bar_color_theme $theme $output_conf

# get wm, border, title bar, active, inactive colors
wm_color_theme $theme $output_conf

exit 0
