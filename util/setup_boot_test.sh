#!/bin/bash
set -e
sdbootDir='./fpga/src/main/resources/vcu118/sdboot'

if [ "$1" == "help" ]
then
    echo "Usage:"
    echo '  with argument `set` to set up'
    echo '  with argument `clean` to clean up'
    exit 0
elif [ $# -ne 2 ] 
then
    echo "Usage:"
    echo '  with argument `set` to set up'
    echo '  with argument `clean` to clean up'
    exit -1
elif [ "$1" == "set" ]
then
    sdbootDir="$2"
    # git clone https://github.com/ljchen98/before-boot-testing.git
    testingDir='./util'
    if [ ! -f "${sdbootDir}/sd.c.backup" ];then
        mv ${sdbootDir}/sd.c ${sdbootDir}/sd.c.backup
        echo "Backup sd.c"
    fi
    if [ ! -f "${sdbootDir}/head.S.backup" ];then
        mv ${sdbootDir}/head.S ${sdbootDir}/head.S.backup
        echo "Backup head.S"
    fi
    if [ ! -f "${sdbootDir}/kprintf.c.backup" ];then
        mv ${sdbootDir}/kprintf.c ${sdbootDir}/kprintf.c.backup
        echo "Backup kprintf.c"
    fi
    if [ ! -f "${sdbootDir}/include/smp.h.backup" ];then
        mv ${sdbootDir}/include/smp.h ${sdbootDir}/include/smp.h.backup
        echo "Backup smp.h"
    fi
    if [ ! -f "${sdbootDir}/linker/memory.lds.backup" ];then
        mv ${sdbootDir}/linker/memory.lds ${sdbootDir}/linker/memory.lds.backup
        echo "Backup memory.lds"
    fi
    if [ ! -f "${sdbootDir}/Makefile.backup" ];then
        mv ${sdbootDir}/Makefile ${sdbootDir}/Makefile.backup
        echo "Backup Makefile"
    fi
    cp ${testingDir}/sd.c ${sdbootDir}/sd.c
    cp ${testingDir}/head.S ${sdbootDir}/head.S
    cp ${testingDir}/kprintf.c ${sdbootDir}/kprintf.c
    cp ${testingDir}/smp.h ${sdbootDir}/include/smp.h
    cp ${testingDir}/memory.lds ${sdbootDir}/linker/memory.lds
    cp ${testingDir}/Makefile ${sdbootDir}/Makefile
    # rm -rf ${testingDir}
    cd ${sdbootDir}
    make clean
    make
    echo "Set Finished."
    exit 0
elif [ "$1" == "clean" ]
then
    sdbootDir="$2"
    mv ${sdbootDir}/sd.c.backup ${sdbootDir}/sd.c
    mv ${sdbootDir}/head.S.backup ${sdbootDir}/head.S 
    mv ${sdbootDir}/kprintf.c.backup ${sdbootDir}/kprintf.c 
    mv ${sdbootDir}/include/smp.h.backup ${sdbootDir}/include/smp.h
    mv ${sdbootDir}/linker/memory.lds.backup ${sdbootDir}/linker/memory.lds
    mv ${sdbootDir}/Makefile.backup ${sdbootDir}/Makefile
    echo "Clean Finished."
    exit 0
else
    echo "Argument 1: $1"
    echo "Argument 2: $2"
    echo 'Unknown argument. Use argument `help` to learn more. Exit.'
    exit -1
fi







