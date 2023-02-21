
#!/bin/bash

############
# Usage
# Pass a path to watch, a file filter, and a command to run when those files are updated
#
# Example:
# watch.sh "node_modules/everest-*/src/templates" "*.handlebars" "ynpm compile-templates"
############

# trap ctrl-c and call ctrl_c()
trap ctrl_c INT

stop_app() {
    PID=`ps aux | grep main.tcl | egrep -v grep | awk '{print $2}'`
    if [ "$PID" != "" ]; then
        echo "stop app pid $PID at `date +"%Y-%m-%d %H:%M:%S"`"
        kill $PID
    fi    
}

ctrl_c() {
    echo "**CTRL-C"
    stop_app
    exit 0
}

watch() {
    WORKING_PATH=$(pwd)
    DIR="./"
    FILTER="*.tcl"
    COMMAND="./main.tcl"
    chsum1=""


    while true
    do
        PID=`ps aux | grep main.tcl | egrep -v grep | awk '{print $2}'`

        chsum2=$(find -L $WORKING_PATH/$DIR -type f -name "$FILTER" -exec md5sum {} \;)
        if [ "$chsum1" != "$chsum2" ] ; then
            clear
            echo "File change, stopping app and executing $COMMAND..."
            stop_app
            $COMMAND &
            chsum1=$chsum2
            echo "..........................................................."
        fi
        sleep 2
    done

}

watch "$@"
