#!/usr/bin/env bash

# first arg: abs path to source exe
# second arg: abs path to dest exe
# second arg: abs path to entitlements

((cp -v $1 $2) && codesign -s - -f --entitlements $3 $2) || (rm -v $2)

# done