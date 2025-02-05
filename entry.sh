#!/bin/bash

/usr/bin/check_arch_arm
RET=$?

if [ "$RET" -eq 1 ]; then
    export LD_PRELOAD=""
fi

/grade/tests/entry.sh

