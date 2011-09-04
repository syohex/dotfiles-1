#!/bin/sh

INTERVAL="60"
TARGET_DIR="~/kui"

GC_INTERVAL=20

main(){

    local log_dir=`dirname $LOG_FILE`
    if ! [ -d "$log_dir" ] 
    then
        mkdir -p -v "$log_dir"
    fi

    if ! is_git_dir
    then
        echo "$target_dir is not a git ripository" >&2
        exit 1
    fi

    trap 'sigint_hook' 2

    echo "start sync (pid: $$)" | logger
    count=0
    while true
    do
        sync | logger
        if [ $count -gt $GC_INTERVAL ]
        then
            git gc 2>&1 | logger
            count=0
        fi
        sleep $INTERVAL
        count=$[$count+1]
    done
}

is_git_dir(){
    git status > /dev/null 2>&1
}

logger(){
    local datetime=`date +'%F %T'`
    sed -e "s/^/$datetime /" $1
}

sigint_hook(){
    echo 
    echo "exit $0"
    exit 0
}

sync(){
    git add . 2>&1
    commit --porcelain
    commit --quiet
    git push --quiet 2>&1 | grep -v "^Everything up-to-date$"
    git pull --ff 2>&1 | grep -v "^Already up-to-date.$"
}


commit(){
    options="$*"
    git commit --all --message "`date +'%F %T'` $0" $options 2>&1 |\
      grep -v "^# On branch master$" |\
      grep -v "^nothing to commit (working directory clean)$"
 }
 
main
