#!/usr/bin/env fish

set lock /tmp/snipshot.lock
set dir /home/nick/pictures
set path $dir/snipshot_(date +%Y-%m-%d_%H-%M-%S).png

# Ensure directory exists
mkdir -p $dir

# Prevent multiple instances
if test -e $lock
    echo "Already running"
    exit
end

touch $lock

# Take screenshot
#grim -g "$(slurp)" $path
#wayfreeze --hide-cursor --before-freeze-cmd 'grim -g "$(slurp)" $path ; killall wayfreeze'

wayfreeze --hide-cursor --before-freeze-cmd "bash -c 'grim -g \"\$(slurp)\" \"$path\"; killall wayfreeze'"

# Copy to clipboard if successful
if test -f $path
    wl-copy < $path
    notify-send -i $path "Screenshot Taken" "Saved to $path"
end

# Remove lock
rm -f $lock
