#!/usr/bin/env fish

set lock /tmp/annotate.lock
set dir ~/pictures
set file $dir/annotate_(date +%Y-%m-%d_%H-%M-%S).png

# Ensure directory exists
mkdir -p $dir

# Prevent multiple instances
if test -e $lock
    echo "Already running"
    exit
end

touch $lock

# Save clipboard image
wl-paste -t image/png > $file

# Check if image exists and not empty
if test -s $file
    satty -f $file
else
    echo "No image in clipboard"
    rm -f $file
end

# Remove lock
rm -f $lock
