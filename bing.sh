#!/bin/bash

bing(){
    if [[ $# -eq 0 ]];then
        echo "query required"
        return 1
    elif [[ $# -eq 1 ]];then
        KEY=$1
    else
        IFS='+'
        KEY="'$*'"
    fi
    curl -s "https://cn.bing.com/dict/(${KEY})?mkt=zh-CN&setlang=ZH" | pup '.qdef > ul text{}'
}

bing "$@"

