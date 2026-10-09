#!/usr/bin/env bash

# "Map Count Setting:"
# sudo sysctl -w vm.max_map_count=1048576 > /dev/null 2>&1

# To make it persistent: Run 'sudo su' in the Terminal and then run: echo "vm.max_map_count=1048576" >> /etc/sysctl.conf
#####################################################################################################################################
### DZL ###
#####################################################################################################################################

modname() {
    local n
    n=$(sed -n 's/^name *= *"\(.*\)";.*/\1/p' "/home/$USER/.steam/steam/steamapps/workshop/content/221100/$1/meta.cpp" 2>/dev/null | head -n1 | tr -d '\r') || true
    echo "${n:-$1}"
}

check_updates() {
    UPD_OUT=()
    local all=("$@") chunk args i n id tu resp
    for (( n=0; n<${#all[@]}; n+=100 )); do
        chunk=("${all[@]:n:100}")
        args=()
        for i in "${!chunk[@]}"; do args+=(-d "publishedfileids[$i]=${chunk[i]}"); done
        resp=$(curl -sS -m 15 -d "itemcount=${#chunk[@]}" "${args[@]}" "https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1/") || return 1
        jq -e '.response.publishedfiledetails' >/dev/null 2>&1 <<< "$resp" || return 1
        while IFS=$'\t' read -r id tu; do
            if [[ -z $(find "/home/$USER/.steam/steam/steamapps/workshop/content/221100/$id" -type f -newermt "@$tu" -print -quit 2>/dev/null) ]]; then
                UPD_OUT+=("$id")
            fi
        done < <(jq -r '.response.publishedfiledetails[] | select(.result == 1) | "\(.publishedfileid)\t\(.time_updated)"' <<< "$resp")
    done
    return 0
}

waitkey() {
    local k seq c mrest
    printf '\e[?1000h\e[?1006h'
    while true; do
        read -s -n1 k || true
        if [[ -z $k ]]; then
            printf '\e[?1000l\e[?1006l'
            return 0
        fi
        if [[ $k == $'\e' ]]; then
            seq=""
            read -s -t 0.05 -n2 seq || true
            if [[ -z $seq ]]; then
                printf '\e[?1000l\e[?1006l'
                return 1
            fi
            if [[ $seq == "[<" ]]; then
                mrest=""; c=""
                until [[ $c == M || $c == m ]]; do
                    c=""
                    read -s -t 0.05 -n1 c || break
                    mrest+=$c
                done
                if [[ ${mrest%%;*} == 0 && ${mrest: -1} == m ]]; then
                    printf '\e[?1000l\e[?1006l'
                    return 0
                fi
                if [[ ${mrest%%;*} == 2 && ${mrest: -1} == m ]]; then
                    printf '\e[?1000l\e[?1006l'
                    return 1
                fi
            fi
        fi
    done
}

readesc() {
    local k v seq
    while true; do
        read -s -n1 k || true
        if [[ $k == $'\e' ]]; then
            seq=""
            read -s -t 0.05 -n2 seq || true
            [[ -n $seq ]] && continue
            echo ""
            return 1
        fi
        break
    done
    v="$k"
    if [[ -n $k ]]; then
        read -r -e -i "$k" v || true
    fi
    printf -v "$1" '%s' "$v"
}

pickmenu() {
    local items=("$@") cnt=$# sel=1 i t k seq c mrest
    number=""
    printf '\e[?1000h\e[?1006h'
    until [[ -n $number ]]; do
        clear
        if [[ -n $PICKTITLE ]]; then echo "$PICKTITLE"; fi
        echo ""
        for (( i=1; i<=cnt; i++ )); do
            t=" $i) ${items[i-1]}"
            if (( i == sel )); then echo -e "\e[100;97m$t\e[0m"; else echo "$t"; fi
        done
        echo ""
        echo ""
        echo ""
        echo "Up/Down = Move   Enter = Select   Esc = Back"
        # echo ""
        echo "Left MB = Enter   Right MB = Esc"
        read -s -n1 k || true
        if [[ $k == $'\e' ]]; then
            seq=""
            read -s -t 0.05 -n2 seq || true
            if [[ $seq == "[A" ]]; then
                if (( sel > 1 )); then sel=$((sel-1)); fi
            elif [[ $seq == "[B" ]]; then
                if (( sel < cnt )); then sel=$((sel+1)); fi
            elif [[ -z $seq && -n $PICKESC ]]; then
                number=$PICKESC
            elif [[ $seq == "[<" ]]; then
                mrest=""; c=""
                until [[ $c == M || $c == m ]]; do
                    c=""
                    read -s -t 0.05 -n1 c || break
                    mrest+=$c
                done
                if [[ ${mrest%%;*} == 64 ]]; then
                    if (( sel > 1 )); then sel=$((sel-1)); fi
                elif [[ ${mrest%%;*} == 65 ]]; then
                    if (( sel < cnt )); then sel=$((sel+1)); fi
                elif [[ ${mrest%%;*} == 0 && ${mrest: -1} == m ]]; then
                    number=$sel
                elif [[ ${mrest%%;*} == 2 && ${mrest: -1} == m && -n $PICKESC ]]; then
                    number=$PICKESC
                fi
            fi
        elif [[ -z $k ]]; then
            number=$sel
        elif [[ $k =~ ^[1-9]$ ]] && (( k <= cnt )); then
            number=$k
        fi
    done
    printf '\e[?1000l\e[?1006l'
    PICKESC=""
    PICKTITLE=""
}

readnum() {
    local k rest seq
    while true; do
        read -s -n1 -p "#? " k
        if [[ $k == $'\e' ]]; then
            read -s -t 0.05 -n2 seq
            [[ -n $seq ]] && continue
            echo ""
            return 1
        fi
        [[ -z $k ]] && continue
        read -r -p "$k" rest
        num="$k$rest"
        return 0
    done
}

startmenu() {

# startmenu() {

# unset number
number=$FAVBACK; unset FAVBACK
msel=0
printf '\e[?1000h\e[?1006h'
until [[ $number == +([1-4]) ]] ; do
    clear
    echo "╔═══════════════════════════════╗"
    echo "║    DZL - DayZ Mod Launcher    ║"
    echo "╚═══════════════════════════════╝"
    echo ""
    echo " Select:"
    echo ""
    for n in 1 2 3 4; do
        case $n in 1) t=" 1) Setup Server & Mods";; 2) t=" 2) Favorites";; 3) t=" 3) Mods";; 4) t=" 4) Quit";; esac
        if (( n == msel )); then echo -e "\e[100;97m$t\e[0m"; else echo "$t"; fi
    done
        echo ""
        echo ""
        echo ""
        echo "Up/Down = Move   Enter = Select   Esc = Back"
        # echo ""
        echo "Left MB = Enter   Right MB = Esc"
    read -s -n1 number || true
    if [[ $number == $'\e' ]]; then
        number=""
        seq=""
        read -s -t 0.05 -n2 seq || true
        if [[ $seq == "[A" ]]; then
            if (( msel > 1 )); then msel=$((msel-1)); elif (( msel == 0 )); then msel=1; fi
        elif [[ $seq == "[B" ]]; then
            if (( msel < 4 )); then msel=$((msel+1)); fi
        elif [[ $seq == "[<" ]]; then
            mrest=""; c=""
            until [[ $c == M || $c == m ]]; do
                c=""
                read -s -t 0.05 -n1 c || break
                mrest+=$c
            done
            if [[ ${mrest%%;*} == 64 ]]; then
                if (( msel > 1 )); then msel=$((msel-1)); elif (( msel == 0 )); then msel=1; fi
            elif [[ ${mrest%%;*} == 65 ]]; then
                if (( msel < 4 )); then msel=$((msel+1)); fi
            elif [[ ${mrest%%;*} == 0 && ${mrest: -1} == m ]]; then
                number=$msel
            fi
        fi
    elif [[ -z $number ]]; then
        number=$msel
    fi
done
printf '\e[?1000l\e[?1006l'
case ${number} in

######################################################
#### Normal Mod Setup Start ##########################
######################################################

[1] )
INPUT=()
clear
echo ""
echo -e "\n
 Server Info can be found at: https://www.battlemetrics.com/servers/dayz/"
sleep 0.5
echo ""

echo -e "\n
 Enter IP-Address:Port\n"
readesc SSERVER || { main; return; }
sleep 0.5

echo -e "\n
 Enter Query Port Number\n"
readesc PPORT || { main; return; }
sleep 0.5

echo -e "\n
 Enter Username\n"
readesc NNAME || { main; return; }
sleep 0.5;;


######################################################
#### Normal Mod Setup End ############################
######################################################



######################################################
#### Menu Options Start      #########################
######################################################

[2] )
clear
dir="/home/$USER/DZL/Favorites/"
check_dir "$dir"

list=$(ls -tr "$dir" | sed 's/\.sh$//')
if [[ -z "$list" ]]; then
    echo ""
    echo "No Favorites Added!"
    echo ""
    sleep 1.5
    main
    return
fi
reload=1
sel=0
top=0
printf '\e[?1000h\e[?1006h'
while true; do
    if (( reload )); then
        favs=($(ls -tr "$dir" | sed 's/\.sh$//'))
        reload=0
    fi
    if [[ ${#favs[@]} -eq 0 ]]; then
        printf '\e[?1000l\e[?1006l'
        main
        return
    fi
    if (( sel >= ${#favs[@]} )); then sel=$(( ${#favs[@]} - 1 )); fi
    rows=$(( $(tput lines) - 6 ))
    if (( rows < 1 )); then rows=1; fi
    if (( sel < top )); then top=$sel; fi
    if (( sel >= top + rows )); then top=$(( sel - rows + 1 )); fi
    clear
    echo "Favorite Servers:"
    echo ""
    echo ""
    for (( i=top; i<top+rows && i<${#favs[@]}; i++ )); do
        if (( i == sel )); then echo -e "\e[100;97m$((i+1)) ) ${favs[i]}\e[0m"; else echo "$((i+1)) ) ${favs[i]}"; fi
    done
        echo ""
        echo ""
        echo ""
        echo "Up/Down = Move   Enter = Select   Esc = Back"
        # echo ""
        echo "Left MB = Enter    Right MB = Esc"
    read -s -n1 k || true
    if [[ $k == $'\e' ]]; then
        seq=""
        read -s -t 0.05 -n2 seq || true
        if [[ $seq == "[A" ]]; then
            if (( sel > 0 )); then sel=$((sel-1)); fi
        elif [[ $seq == "[B" ]]; then
            if (( sel < ${#favs[@]} - 1 )); then sel=$((sel+1)); fi
        elif [[ $seq == "[<" ]]; then
            mrest=""; c=""
            until [[ $c == M || $c == m ]]; do
                c=""
                read -s -t 0.05 -n1 c || break
                mrest+=$c
            done
            if [[ ${mrest%%;*} == 64 ]]; then
                if (( sel > 0 )); then sel=$((sel-1)); fi
            elif [[ ${mrest%%;*} == 65 ]]; then
                if (( sel < ${#favs[@]} - 1 )); then sel=$((sel+1)); fi
            elif [[ ${mrest%%;*} == 0 && ${mrest: -1} == m ]]; then
                k=""
            elif [[ ${mrest%%;*} == 2 && ${mrest: -1} == m ]]; then
                printf '\e[?1000l\e[?1006l'
                main
                return
            fi
        elif [[ -z $seq ]]; then
            printf '\e[?1000l\e[?1006l'
            main
            return
        fi
    fi
    if [[ -z $k ]]; then
        osel=1
        o=""
        until [[ $o == 1 || $o == 2 || $o == 3 || $o == 4 || $o == $'\e' ]]; do
            clear
            echo "${favs[sel]}:"
            echo ""
            for n in 1 2 3 4; do
                case $n in 1) t="1) Launch Server";; 2) t="2) Edit File";; 3) t="3) Rename Favorite";; 4) t="4) Delete Favorite";; esac
                if (( n == osel )); then echo -e "\e[100;97m$t\e[0m"; else echo "$t"; fi
            done
        echo ""
        echo ""
        echo ""
        echo "Up/Down = Move   Enter = Select   Esc = Back"
        # echo ""
        echo "Left MB = Enter    Right MB = Esc"
            read -s -n1 o || true
            if [[ $o == $'\e' ]]; then
                seq=""
                read -s -t 0.05 -n2 seq || true
                if [[ $seq == "[A" ]]; then
                    if (( osel > 1 )); then osel=$((osel-1)); fi
                    o=""
                elif [[ $seq == "[B" ]]; then
                    if (( osel < 4 )); then osel=$((osel+1)); fi
                    o=""
                elif [[ $seq == "[<" ]]; then
                    mrest=""; c=""
                    until [[ $c == M || $c == m ]]; do
                        c=""
                        read -s -t 0.05 -n1 c || break
                        mrest+=$c
                    done
                    if [[ ${mrest%%;*} == 64 ]]; then
                        if (( osel > 1 )); then osel=$((osel-1)); fi
                    elif [[ ${mrest%%;*} == 65 ]]; then
                        if (( osel < 4 )); then osel=$((osel+1)); fi
                    elif [[ ${mrest%%;*} == 0 && ${mrest: -1} == m ]]; then
                        o=$osel
                        continue
                    elif [[ ${mrest%%;*} == 2 && ${mrest: -1} == m ]]; then
                        o=$'\e'
                        continue
                    fi
                    o=""
                elif [[ -n $seq ]]; then
                    o=""
                fi
            elif [[ -z $o ]]; then
                o=$osel
            fi
        done
        if [[ $o == 1 ]]; then
            echo ""
            printf '\e[?1000l\e[?1006l'
            echo "Launching: ${favs[sel]}"
            sh "/home/$USER/DZL/Favorites/${favs[sel]}.sh"
            break
        elif [[ $o == 2 ]]; then
            printf '\e[?1000l\e[?1006l'
            "${EDITOR:-nano}" "$dir${favs[sel]}.sh" || true
            printf '\e[?1000h\e[?1006h'
        elif [[ $o == 3 ]]; then
            printf '\e[?1000l\e[?1006l'
            echo ""
            read -r -p "New name: " nn || true
            nn="${nn//[^[:alnum:]_.-]/_}"
            if [[ -n $nn ]]; then
                mv -n "$dir${favs[sel]}.sh" "$dir$nn.sh" || true
                reload=1
            fi
            printf '\e[?1000h\e[?1006h'
        elif [[ $o == 4 ]]; then
            clear
            echo ""
            echo "Delete ${favs[sel]}?"
            echo ""
            echo ""
            echo ""
            echo "Enter = Delete   Esc = Back"
            echo ""
            echo "Left MB = Enter    Right MB = Esc"
            if waitkey; then
                rm "$dir${favs[sel]}.sh"
                reload=1
            fi
        fi
        printf '\e[?1000h\e[?1006h'
    fi
done



exit
echo ""

startmenu "${dir_dayz}" "${dir_workshop}" || exit 1;;


[3] )
clear
submenur1 2
sleep 0.1;;

[4] )
clear
exit;;

esac
}

submenur1(){
number=$1



#echo ""
case $number in

"3") ######################################################################################
clear

read -s -n1 -p $'\n
 WARNING: This deletes ALL DayZ mods.
 Press Enter to continue and press Esc to go back' foo
[[ -z $foo ]] || { submenur1 2; return; }


      	    rm -rf /home/$USER/.steam/steam/steamapps/workshop/content/221100/*
     	    sleep 0.1
            rm -rf /home/$USER/.steam/steam/steamapps/workshop/downloads/*
            sleep 0.1
     	    rm -r -f /home/$USER/.steam/steam/steamapps/common/DayZ/@*

main;;


"2")

# main;;
#    exit;;
sel=9999
top=0
reload=1
printf '\e[?1000h\e[?1006h'
while true; do
    if (( reload )); then
        mfavs=(); mnames=()
        while IFS=$'\t' read -r n m; do mnames+=("$n"); mfavs+=("$m"); done < <(for m in $(ls /home/$USER/.steam/steam/steamapps/workshop/content/221100/); do printf '%s\t%s\n' "$(modname "$m")" "$m"; done | sort -f -t $'\t' -k1,1)
        reload=0
    fi
    if [[ ${#mfavs[@]} -eq 0 ]]; then
        clear
        echo ""
        echo "No Mods Detected"
        sleep 1.5
        printf '\e[?1000l\e[?1006l'
        main
        return
    fi
    if (( sel >= ${#mfavs[@]} )); then sel=$(( ${#mfavs[@]} - 1 )); fi
    # rows=$(( $(tput lines) - 7 ))
    rows=$(( $(tput lines) - 9 ))
    if (( rows < 1 )); then rows=1; fi
    if (( sel < top )); then top=$sel; fi
    if (( sel >= top + rows )); then top=$(( sel - rows + 1 )); fi
    clear
    echo "Installed Mods:"
    echo ""
    for (( i=top; i<top+rows && i<${#mfavs[@]}; i++ )); do
        if (( i == sel )); then echo -e "\e[100;97m${mnames[i]}\e[0m"; else echo "${mnames[i]}"; fi
    done
    echo ""
        echo "U = Check For Updates"
        echo ""
        echo "Ctrl+Del = Delete All Mods"
        echo ""
        echo ""
        echo ""
        echo "Up/Down = Move   Enter = Select   Esc = Back"
        echo "Left MB = Enter    Right MB = Esc"
        # echo ""
        # echo "Left MB = Enter    Right MB = Esc"
    read -s -n1 k || true
    if [[ $k == $'\e' ]]; then
        seq=""
        read -s -t 0.05 -n2 seq || true
        if [[ $seq == "[A" ]]; then
            if (( sel > 0 )); then sel=$((sel-1)); fi
        elif [[ $seq == "[B" ]]; then
            if (( sel < ${#mfavs[@]} - 1 )); then sel=$((sel+1)); fi
        elif [[ $seq == "[<" ]]; then
            mrest=""; c=""
            until [[ $c == M || $c == m ]]; do
                c=""
                read -s -t 0.05 -n1 c || break
                mrest+=$c
            done
            if [[ ${mrest%%;*} == 64 ]]; then
                if (( sel > 0 )); then sel=$((sel-1)); fi
            elif [[ ${mrest%%;*} == 65 ]]; then
                if (( sel < ${#mfavs[@]} - 1 )); then sel=$((sel+1)); fi
            elif [[ ${mrest%%;*} == 0 && ${mrest: -1} == m ]]; then
                k=""
            elif [[ ${mrest%%;*} == 2 && ${mrest: -1} == m ]]; then
                printf '\e[?1000l\e[?1006l'
                main
                return
            fi
        elif [[ $seq == "[3" ]]; then
            crest=""
            read -s -t 0.05 -n3 crest || true
            if [[ $crest == ";5~" ]]; then
                printf '\e[?1000l\e[?1006l'
                submenur1 3
                return
            fi
        elif [[ -z $seq ]]; then
            printf '\e[?1000l\e[?1006l'
            main
            return
        fi
    fi

    if [[ $k == [uU] ]]; then
        printf '\e[?1000l\e[?1006l'
        clear
        echo "Checking for updates .."
        if check_updates "${mfavs[@]}"; then
            clear
            echo "Mod Updates:"
            echo ""
            if (( ${#UPD_OUT[@]} == 0 )); then
                echo "All mods are up to date."
                echo ""
                echo ""
                echo ""
                echo "Enter / Esc = Back"
                # echo ""
                echo "Left MB = Enter    Right MB = Esc"
                waitkey || true
            else
                for id in "${UPD_OUT[@]}"; do echo "Update available: $(modname "$id")"; done
                echo ""
                echo "Removed mods download again on the next Join."
        echo "Up/Down = Move   Enter = Select   Esc = Back"
        # echo ""
        echo "Left MB = Enter   Right MB = Esc"
                if waitkey; then
                    for id in "${UPD_OUT[@]}"; do rm -rf "/home/$USER/.steam/steam/steamapps/workshop/content/221100/${id}"; done
                    reload=1
                fi
            fi
        else
            echo "Update check failed."
            sleep 2
        fi
        printf '\e[?1000h\e[?1006h'
    fi
    if [[ -z $k ]]; then
        id="${mfavs[sel]}"
        while true; do
            PICKTITLE="${mnames[sel]}"
            PICKESC=0
            pickmenu "Update Mod" "Delete Mod" "Mod Info"
            case $number in
                1)
                    clear
                    echo "${mnames[sel]}"
                    echo ""
                    echo "Checking for updates .."
                    if check_updates "$id"; then
                        if (( ${#UPD_OUT[@]} )); then
                            echo "Update found. Downloading .."
                            acf="$HOME/.steam/steam/steamapps/workshop/appworkshop_221100.acf"
                            rm -rf "/home/$USER/.steam/steam/steamapps/workshop/content/221100/$id"
                            rm -f "$acf"
                            steam steam+workshop_download_item 221100 "$id" && wait
                            until [[ -f "$acf" ]]; do sleep 2; done
                            while grep -q '"NeedsDownload"[[:space:]]*"1"' "$acf"; do
                                echo "..Downloading. Please wait.."
                                sleep 2
                            done
                            echo "Update finished."
                        else
                            echo "Already up to date."
                                echo ""
                                    echo ""
                        fi
                    else
                        echo "Update check failed."
                            echo ""
                                echo ""
                                    echo ""
                    fi
                    echo ""
                        echo ""
        echo "Up/Down = Move   Enter = Select   Esc = Back"
        # echo ""
        echo "Left MB = Enter   Right MB = Esc"
                    waitkey || true
                    reload=1
                    break
                    ;;
                2)
                    clear
                    echo ""
                    echo "Delete ${mnames[sel]}?"
                    echo ""
                    echo ""
                    echo ""
        echo "Up/Down = Move   Enter = Select   Esc = Back"
        # echo ""
        echo "Left MB = Enter   Right MB = Esc"
                    if waitkey; then
                        rm -rf "/home/$USER/.steam/steam/steamapps/workshop/content/221100/$id"
                        reload=1
                        break
                    fi
                    ;;
                3)
                    clear
                    base="/home/$USER/.steam/steam/steamapps/workshop/content/221100/$id"
                    lt=$(find "$base" -type f -printf '%T@\n' 2>/dev/null | sort -n | tail -n1 | cut -d. -f1) || lt=""
                    au=$(sed -n 's/^author *= *"\(.*\)";.*/\1/p' "$base/mod.cpp" 2>/dev/null | head -n1 | tr -d '\r') || au=""
                    info=$(curl -sS -m 15 -d "itemcount=1" -d "publishedfileids[0]=$id" "https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1/" 2>/dev/null | jq -r '.response.publishedfiledetails[0] | select(.result == 1) | "\(.time_updated)\t\(.time_created)\t\(.subscriptions)"' 2>/dev/null) || info=""
                    tu=""; tc=""; subs=""
                    IFS=$'\t' read -r tu tc subs <<< "$info" || true
                    echo "${mnames[sel]}"
                    echo ""
                    echo "Workshop ID:   $id"
                    echo "Workshop page: https://steamcommunity.com/sharedfiles/filedetails/?id=$id"
                    if [[ -n $au ]]; then echo "Author:        $au"; fi
                    echo "Size on disk:  $(du -sh "$base" 2>/dev/null | cut -f1)"
                    if [[ $lt =~ ^[0-9]+$ ]]; then echo "Local files:   $(date -d "@$lt" '+%Y-%m-%d %H:%M')"; fi
                    if [[ $tu =~ ^[0-9]+$ ]]; then
                        echo "Steam updated: $(date -d "@$tu" '+%Y-%m-%d %H:%M')"
                        if [[ $tc =~ ^[0-9]+$ ]]; then echo "Steam created: $(date -d "@$tc" '+%Y-%m-%d %H:%M')"; fi
                        echo "Subscribers:   $subs"
                        if [[ -z $(find "$base" -type f -newermt "@$tu" -print -quit 2>/dev/null) ]]; then
                            echo "Status:        Update available"
                        else
                            echo "Status:        Up to date"
                        fi
                    else
                        echo "Steam info unavailable."
                    fi
                    echo ""
        # echo "Up/Down = Move   Enter = Select   Esc = Back"
        # echo ""
        # echo "Left MB = Enter   Right MB = Esc"
                    waitkey || true
                    ;;
                *)
                    break
                    ;;
            esac
        done
        printf '\e[?1000h\e[?1006h'
    fi
done
;;

"4") ######################################################################################
clear
esac

}


######################################################
#### Menu Options Stop       #########################
######################################################


set -eo pipefail

SELF=$(basename "$(readlink -f "${0}")")

DAYZ_ID=221100

DEFAULT_GAMEPORT=2302
DEFAULT_QUERYPORT=27016

API_URL="https://dayzsalauncher.com/api/v1/query/@ADDRESS@/@PPORT@"
API_PARAMS=(
  -sSL
  -m 10
  -H "User-Agent: $USER"
)
WORKSHOP_URL="https://steamcommunity.com/sharedfiles/filedetails/SubscribeItem/?id=@ID@"

SSERVER=""
PPORT="${DEFAULT_QUERYPORT}"
DEBUG=0
LAUNCH=0
STEAM=""
SERVER=""
PORT="${DEFAULT_QUERYPORT}"
NAME=""
NNAME=""
INPUT=()
MODS=()
MODS2=()
PARAMS=()
IP=()
PORT=()

declare -A DEPS=(

  [gawk]="required for mod metadata. Try: sudo pacman -S gawk"
  [curl]="required for the server API. Try: sudo pacman -S curl"
  [jq]="required for the server API's JSON response. Try: sudo pacman -S jq"
)

print_help() {
    echo "Usage: ${SELF}"
}

while (( "$#" )); do
  case "${1}" in
    -h|--help)
      print_help
      exit
      ;;
    -d|--debug)
      DEBUG=1
      ;;
    --steam)
      STEAM="${2}"
      shift
      ;;
    -l|--launch)
      LAUNCH=1
      ;;
    -s|--server)
      SERVER="${2}"
      [[ "${SERVER}" = *:* ]] || SERVER="${SERVER}:${DEFAULT_GAMEPORT}"
      shift
      ;;
    -p|--port)
      PORT="${2}"
      shift
      ;;
    -n|--name)
      NAME="${2}"
      shift
      ;;
    --)
      shift
      PARAMS+=("${@}")
      LAUNCH=1
      break
      ;;
    *)
      INPUT+=("${1}")
      ;;
  esac
  shift
done

err() {
echo -e >&2 "[${SELF}][error] ${@}"

exit 1
}

msg() {

echo "[${SELF}][info] ${@}"
}

debug() {
if [[ ${DEBUG} == 1 ]]; then
echo "[${SELF}][debug] ${@}"
  fi
}

#check_dir() {

#debug "Checking directory: ${1}"
#if [ ! -d "${1}" ] ; then
#mkdir "/home/$USER/.steam/steam/steamapps/workshop/content/221100"
#fi
#}

check_dir() {
    if [[ ! -d "${1}" ]]; then
        mkdir -p "${1}" || { echo "Error: could not create ${1}" >&2; return 1; }
    fi
}

check_dep() {
  command -v "${1}" >/dev/null 2>&1
}

check_deps() {
  for dep in "${!DEPS[@]}"; do
    check_dep "${dep}" || err "'${dep}' not installed (${DEPS["${dep}"]})"
done
}

dec2base64() {
  echo "$1" \
    | LC_ALL=C gawk '
      {
        do {
          printf "%c", and($1, 255)
          $1 = rshift($1, 8)
        } while ($1 > 0)
      }
    ' \
    | base64 \
    | sed 's|/|-|g; s|+|_|g; s|=||g'
}

resolve_steam() {
    if [[ -n "${STEAM}" ]]; then
    check_dep "${STEAM}" || err "Could not find the '${STEAM}' executable"
    fi

    if check_dep steam; then
    STEAM=steam
    fi
}

query_server_api() {

  [[ -z "${SSERVER}" ]] && return

  local query
  local response
  echo ""
  echo -e "\n
 Server IP   : $SSERVER
 Query Port  : $PPORT
 UserName    : $NNAME"

  query="$(sed -e "s/@ADDRESS@/${SSERVER%:*}/" -e "s/@PPORT@/${PPORT}/" <<< "${API_URL}")"
  debug "Querying ${query}"
  response="$(curl "${API_PARAMS[@]}" "${query}")"
  debug "Parsing API response"
  jq -e '.result.mods | select(type == "array")' >/dev/null 2>&1 <<< "${response}" || err " Missing data from API response. Try again in a few seconds"
  jq -e '.result.mods[]' >/dev/null 2>&1 <<< "${response}" || { echo ""; echo ""; echo -e " This is a Vanilla Server.";}

  INPUT+=( $(jq -r ".result.mods[] | .steamWorkshopId" <<< "${response}") )
}

mainmenu(){

sleep 0.25
if [ -f "/home/$USER/.steam/steam/steamapps/workshop/appworkshop_221100.acf" ] ; then
rm /home/$USER/.steam/steam/steamapps/workshop/appworkshop_221100.acf
fi
sleep 0.25
if [ -f "/home/$USER/.steam/steam/steamapps/workshop/appworkshop_241100.acf" ] ; then
rm /home/$USER/.steam/steam/steamapps/workshop/appworkshop_241100.acf
fi
sleep 0.25

missing=0

unset number
# pickmenu "Join Server" "Add To Favorites" "Edit Server Mods (For This Server Only)" "Main Menu"
PICKESC=4
pickmenu "Join Server" "Add To Favorites" "Edit Server Mods (For This Server Only)" "Main Menu"
case $number in
    [1])
    clear
	    echo ""
	    echo -e "\n
 Checking Server Mods .."
            sleep 0.25
            rm -rf /home/$USER/.steam/steam/steamapps/workshop/content/downloads/*
            rm -r -f /home/$USER/.steam/steam/steamapps/common/DayZ/@*
            sleep 0.1;;
    [2])
    submenu2
    ;;
    [3])
    submenu1
    ;;
    [4])
    main
    ;;
        *)
        echo "invalid answer, please try again"
        ;;

esac

}

submenu1(){
unset number
PICKESC=3
pickmenu "Verify Mods" "Remove Mods Used By This Server"

#echo ""
case $number in

"1") ######################################################################################

clear
read -p $'\n
 Press Enter to Verify Mods for this Server.
\n' foo
            sleep 0.25
            for modid in "${INPUT[@]}"; do
	    rm -rf /home/$USER/.steam/steam/steamapps/workshop/content/221100/${modid}
	    rm -r -f /home/$USER/.steam/steam/steamapps/common/DayZ/@*
	    continue
	   done
            sleep 0.1
            rm -rf /home/$USER/.steam/steam/steamapps/workshop/content/downloads/*
            sleep 0.1
            rm -r -f /home/$USER/.steam/steam/steamapps/common/DayZ/@*
            sleep 0.1
            if [ -f "/home/$USER/.steam/steam/steamapps/workshop/appworkshop_221100.acf" ] ; then
            rm /home/$USER/.steam/steam/steamapps/workshop/appworkshop_221100.acf
            fi
sleep 0.1;;

"2") ######################################################################################

   unset mods2
   MODS2=() #New
   for modid in "${INPUT[@]}"; do

    local modpath2="${dir_workshop}/${modid}"
    local namelink="${modid}"
    MODS2+=("${namelink}")
    # local mods2="$(IFS=";" echo "${MODS2[*]}")"
    local mods2="$(IFS=";"; echo "${MODS2[*]}")"
done

clear
read -p $'\n
 Press Enter to Delete Mods Used By This Server.
\n' foo
echo -e "\n
 Mods Deleted:\n ${mods2}\n From Workshop Directory: \n ${dir_workshop}"
            sleep 0.1
	    for modid in "${INPUT[@]}"; do
	    rm -rf /home/$USER/.steam/steam/steamapps/workshop/content/221100/${modid}
	    continue
	    done
            rm -rf /home/$USER/.steam/steam/steamapps/workshop/downloads/*
            sleep 0.1
	    rm -r -f /home/$USER/.steam/steam/steamapps/common/DayZ/@*
            if [ -f "/home/$USER/.steam/steam/steamapps/workshop/appworkshop_221100.acf" ] ; then
            rm /home/$USER/.steam/steam/steamapps/workshop/appworkshop_221100.acf
            fi
#exit;;

mainmenu "${dir_dayz}" "${dir_workshop}" || exit 1;;

"3") ######################################################################################

    mainmenu
    ;;

esac

}

submenu2(){

    clear
    ppath=/home/$USER/DZL/Favorites/
    check_dir "$ppath"
    echo -e "\n
 Save Favorite As:
 ";

    echo ""
    echo ""
    echo " Esc = Back"
    echo ""
    # read fname;
    readesc fname || { mainmenu; return; }
    fname="${fname//[^[:alnum:]_.-]/_}"
    echo ""
    unset MODS
for modid in "${INPUT[@]}"; do
    local modlink="@$(dec2base64 "${modid}")"
    local modpath="${dir_workshop}/${modid}"
    local modmeta="${modpath}/meta.cpp"
    MODS+=("${modlink}")
    local mods="$(IFS=";"; echo "${MODS[*]}")"
    local modlink="@$(dec2base64 "${modid}")"
    sleep 0.2
done

    # cat > $ppath$fname.sh << ENDMASTER
      cat > "$ppath$fname.sh" << ENDMASTER
steam -applaunch 221100 "-mod=$mods" -connect=${SSERVER} --port ${PPORT} -name=${NNAME} -nolauncher -world=empty
ENDMASTER
    echo -e "\n
 Launch Script Saved In:$ppath$fname.sh";
   echo "";
   echo " This Server Was Added To Favorites";
echo -e "\n
 Launch command for this server: \n\n steam -applaunch 221100 \"-mod=$mods\" -connect=$SSERVER --port ${PPORT} -name=${NNAME} -nolauncher -world=empty"
echo ""
echo "";
mainmenu;
}

mods_setup() {

    local dir_dayz="${1}"
    local dir_workshop="${2}"
    unset MODS

    local installed=() id
    for id in "${INPUT[@]}"; do
        if [[ -d "${dir_workshop}/${id}" ]]; then installed+=("${id}"); fi
    done
    if (( ${#installed[@]} )); then
        echo -e "\n Checking mod updates .."
        if check_updates "${installed[@]}"; then
            if (( ${#UPD_OUT[@]} )); then
                clear
                echo -e "\n Mod updates available:\n"
                for id in "${UPD_OUT[@]}"; do echo "  $(modname "$id")"; done
                echo ""
                echo " Enter = Update them   Esc = Skip"
                echo ""
                echo " Left MB = Enter    Right MB = Esc"
                if waitkey; then
                    for id in "${UPD_OUT[@]}"; do rm -rf "${dir_workshop}/${id}"; done
                    rm -f "$HOME/.steam/steam/steamapps/workshop/appworkshop_221100.acf"
                fi
            fi
        else
            echo " Update check failed, skipping."
            sleep 1
        fi
    fi

for modid in "${INPUT[@]}"; do

    local modlink="@$(dec2base64 "${modid}")"
    local modpath="${dir_workshop}/${modid}"

if ! [[ -d "${modpath}" ]]; then

    missing=1
    echo -e "\n
 MOD MISSING: ${modid}: $(sed -e"s/@ID@/${modid}/" <<< "${WORKSHOP_URL}")
 DOWNLOADING MOD: ${modid}...
  ";
    echo ""
    steam steam+workshop_download_item 221100 ${modid} && wait

  continue
fi

done

if (( missing == 1 )); then
    local acf="$HOME/.steam/steam/steamapps/workshop/appworkshop_221100.acf"
    echo -e "\n Please Wait While Steam Downloads The Mods."
    sleep 2
    until [[ -f "$acf" ]]; do
        sleep 2
    done
    while grep -q '"NeedsDownload"[[:space:]]*"1"' "$acf"; do
        echo -e "\n ..Downloading Mods. Please wait.."
        sleep 2
    done
    echo -e "\n Mods Finished Downloading."
fi
    echo ""
    missing=0
    unset MODS
    for modid in "${INPUT[@]}"; do
    local modlink="@$(dec2base64 "${modid}")"
    local modpath="${dir_workshop}/${modid}"
    local modmeta="${modpath}/meta.cpp"
    ln -sr -f "${modpath}" "${dir_dayz}/${modlink}"
    MODS+=("${modlink}")
    local mods="$(IFS=";"; echo "${MODS[*]}")"
    local modlink="@$(dec2base64 "${modid}")"
  continue

    done

    echo -e "\n
 Name: $NNAME
 Game IP:Port $SSERVER
 Query Port: $PPORT"
    echo ""

   echo -e "\n
 Launch command for this server: \n\n steam -applaunch 221100 \"-mod=$mods\" -connect=$SSERVER --port ${PPORT} -name=${NNAME} -nolauncher -world=empty"
echo ""

#read -p $'\n
# Press " Enter " to Launch DayZ And Join The Server
#\n' foo

read -s -n1 -p $'\n Press " Enter " to Launch DayZ or " Esc " to go back to Main Menu\n' foo
echo ""
echo ""
if [[ $foo == $'\e' ]]; then
    echo -e "\n Going back to Main Menu...\n"
    main
    return
fi
echo -e "\n Starting DayZ.. Please Wait..\n"
steam -applaunch 221100 "-mod=$mods" -connect=${SSERVER} --port ${PPORT} -name=${NNAME} -nolauncher -world=empty
echo ""
exit
}


add_to_favorites() {
while true; do
read -p "Add server to Favorites? (y/n) " yn
case $yn in
    [Yy]* )
         submenu2;;
    [Nn]* )

	 launch_game;;


    * ) echo "invalid response";;

esac
done
echo ""
}

trap 'echo -e "\n Exiting...\n"; exit 0' SIGINT SIGTERM
trap 'printf "\e[?1000l\e[?1006l"' EXIT

launch_game() {
read -p $'\n
 Press " Enter " to Launch DayZ And Join The Server
\n' foo

echo -e "\n
 Starting DayZ.. Please Wait..
\n";
steam -applaunch 221100 "-mod=$mods" -connect=${SSERVER} --port ${PPORT} -name=${NNAME} -nolauncher -world=empty
exit 0;
}


main() {
  check_deps
  resolve_steam

  if [[ -z "${STEAM_ROOT}" ]]; then
  STEAM_ROOT="${XDG_DATA_HOME:-${HOME}/.steam}/steam"
  fi
  STEAM_ROOT="${STEAM_ROOT}/steamapps"
  local dir_dayz="${STEAM_ROOT}/common/DayZ"
  local dir_workshop="${STEAM_ROOT}/workshop/content/${DAYZ_ID}"
  check_dir "${dir_dayz}"
  check_dir "${dir_workshop}"
  startmenu "${dir_dayz}" "${dir_workshop}" || exit 1
  query_server_api
  mainmenu "${dir_dayz}" "${dir_workshop}" || exit 1
  mods_setup "${dir_dayz}" "${dir_workshop}" || exit 1
  local mods="$(IFS=";"; echo "${MODS[*]}")"
  local mods2="$(IFS=";"; echo "${MODS2[*]}")"

}

main
