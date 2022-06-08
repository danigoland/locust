#!/bin/bash

read -r -d '' applescriptCode <<'EOF'
set dialogText to text returned of (display dialog "Enter version (image tag)" default answer "latest")
return dialogText
EOF

tagInput=$(osascript -e "$applescriptCode");

docker buildx build --platform linux/amd64,linux/arm64 -t danigoland/locust:${tagInput} --push .