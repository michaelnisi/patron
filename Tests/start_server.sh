#!/usr/bin/env bash

set -o xtrace

node ./Tests/Server/index.js > /dev/null & echo $! > .pid
