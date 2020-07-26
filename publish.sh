#!/bin/bash

set -e

docker push fl3x3dd/pwngun:$PWNGUN_VERSION

if [ "$PWNGUN_VERSION" == "2.30" ]
then
    docker tag fl3x3dd/pwngun:$PWNGUN_VERSION fl3x3dd/pwngun:latest
    docker push fl3x3dd/pwngun:latest
fi
