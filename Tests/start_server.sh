#!/usr/bin/env bash

set -o xtrace

node server/index.js > /dev/null & echo $! > .pid
