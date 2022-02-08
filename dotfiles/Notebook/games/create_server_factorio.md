# Factorio sv

In data/server-settings-examples.json

set public to false

set verification to false if non-premium

## Create the server

> $ bin/x64/factorio --create saves/server.zip --map-gen-settings data/map-gen-settings.example.json --map-settings data/map-settings.example.json

## Start the server

> $ __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia bin/x64/factorio --start-server saves/blana_gang.zip --server-settings data/server-settings.example.json
