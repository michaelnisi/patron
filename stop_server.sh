#!/usr/bin/env bash

set -o xtrace

kill $(cat .pid)
