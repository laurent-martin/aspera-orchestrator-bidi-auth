#!/bin/bash
# delete aborted downloads
main="$1"
# only address files that are at max 2 seconds old
timeref=$(date -d 'now - 2 seconds' +'%Y-%m-%d %H:%M:%S')
# delete empty partial and corresponding aspx files
find "$main" -type f -empty -name "*.partial" -newermt "$timeref" | while read file; do
    aspx="${file%.partial}.aspx"
    rm -f "$file" "$aspx"
done
# delete empty folders
find "$main" -type d -empty -delete
