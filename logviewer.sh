#!/bin/bash
# configurable params are: SPECIAL_INSTANCE_ID, HOST, END, defaults below
SPECIAL_INSTANCE_ID=${SPECIAL_INSTANCE_ID:-'e2e63350'}
HOST=${HOST:-'ubuntu@ecs-agent-$i.sandbox.centrio.com'}
END=${END:-09}

trap 'kill $(jobs -p)' EXIT

GREEN='\033[32m' # \033[<x>m is colors, 31 is red, 32 is green, 33 is yellow, 34 is blue
END_COLOR='\033[0m'

for i in $(eval echo "{00..$END}"); do
    _curr_host=$(eval echo ${HOST-$DEFAULT_HOST})
    ssh \
        -o StrictHostKeyChecking=no \
        -i ~/.ssh/blendeast.pem $_curr_host \
        "tail -f /mnt/ecs-agent/logs/blend-emblem-${SPECIAL_INSTANCE_ID}/*" \
    | gawk "{ print \"${GREEN}${_curr_host}:${END_COLOR}\", \$0; }"&
done

wait
