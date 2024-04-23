#!/bin/bash

set -e

fly ssh console --pty -C "/app/bin/baddl remote"
