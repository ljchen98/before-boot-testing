set -e
sdbootDir='./fpga/src/main/resources/vcu118/sdboot'

if [ $# -eq 0 ]
then
    echo "Usage:"
    echo '  with argument `set` to set up'
    echo '  with argument `clean` to clean up'
    exit -1
elif [ "$1" == "help" ] 
then
    echo "Usage:"
    echo '  with argument `set` to set up'
    echo '  with argument `clean` to clean up'
    exit 0
elif [ "$1" == "set" ]
then
    git clone https://github.com/ljchen98/before-boot-testing.git
    testingDir='./before-boot-testing'
    mv ${sdbootDir}/sd.c ${sdbootDir}/sd.c.backup
    mv ${sdbootDir}/head.S ${sdbootDir}/head.S.backup
    mv ${sdbootDir}/kprintf.c ${sdbootDir}/kprintf.c.backup
    mv ${sdbootDir}/include/smp.h ${sdbootDir}/include/smp.h.backup
    cp ${testingDir}/sd.c ${sdbootDir}/sd.c
    cp ${testingDir}/head.S ${sdbootDir}/head.S
    cp ${testingDir}/kprintf.c ${sdbootDir}/kprintf.c
    cp ${testingDir}/smp.h ${sdbootDir}/include/smp.h
    rm -rf ${testingDir}
    echo "Set Finished."
    exit 0
elif [ "$1" == "clean" ]
then
    mv ${sdbootDir}/sd.c.backup ${sdbootDir}/sd.c
    mv ${sdbootDir}/head.S.backup ${sdbootDir}/head.S 
    mv ${sdbootDir}/kprintf.c.backup ${sdbootDir}/kprintf.c 
    mv ${sdbootDir}/include/smp.h.backup ${sdbootDir}/include/smp.h
    echo "Clean Finished."
else
    echo 'Unknown argument. Use argument `help` to learn more. Exit.'
    exit -1
fi







