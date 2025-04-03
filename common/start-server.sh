#!/bin/bash
cd /opt/factorio
./factorio/bin/x64/factorio --start-server-load-latest --server-settings ./config/server-settings.json "$@"
