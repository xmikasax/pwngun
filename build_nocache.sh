#!/bin/bash

set -e

docker build --no-cache -t fl3x3dd/pwngun:$PWNGUN_VERSION -f build/Dockerfile.$PWNGUN_VERSION .
