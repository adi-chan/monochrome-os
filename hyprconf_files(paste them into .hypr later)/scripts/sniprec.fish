##!/usr/bin/env fish

#Check if slurp is already running
set pids (pgrep slurp)
if test -n "$pids"
    echo "slurp is running"
    exit
end

# Define temporary directory for video
set temp_dir /home/nick/recording

# Create the temp directory if it doesn't exist
mkdir -p $temp_dir

set timestamp (date "+%Y%m%d_%H%M%S")

# Check if wf-recorder is running
if pgrep -x "wf-recorder" > /dev/null
    echo "wf-recorder is running. Killing it..."
    # Kill wf-recorder process
    pkill -x "wf-recorder"
    echo "wf-recorder has been killed."
    play /home/nick/sounds/RecStop.mp3
    exit
else
    echo "wf-recorder is not running."
end

#Check if the file exists in the specified directory
if test -f "$temp_dir/sniprec.mp4"
   echo "sniprec.mp4 found in $temp_dir. Deleting it..."
    rm "$temp_dir/sniprec.mp4"
    echo "sniprec.mp4 has been deleted."
else
    echo "sniprec.mp4 not found in $temp_dir."
end

# Use slurp to select a region
set region (slurp) ; or exit 

play /home/nick/sounds/RecStart.mp3 &

# Set the output video file path
set output_file "$temp_dir/recording_$timestamp.mp4"

# Start recording with wf-recorder using the selected region
wf-recorder -g $region -aalsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFiSpeakersink.monitor -f $output_file

# Once recording is stopped, copy the video to the clipboard using wl-copy
wl-copy -t text/uri-list "file://$output_file"

# Extract a thumbnail for the notification preview as a hidden file
set basename (basename $output_file)
set thumb_file "$temp_dir/.thumb_$basename.jpg"
ffmpeg -y -i "$output_file" -vframes 1 -q:v 2 "$thumb_file" 2>/dev/null

#notification
notify-send -i "$thumb_file" "Video Recorded" "Saved to $output_file"

# Requirements for this script:
#
# 1. slurp
#    - Lets you select a region of the screen with the mouse
#    - Install: sudo pacman -S slurp
#
# 2. wf-recorder
#    - Records a Wayland screen region to video
#    - Install: sudo pacman -S wf-recorder
#
# 3. sox
#    - Plays sound effects for start/stop
#    - Install: sudo pacman -S sox
#
# 4. wl-clipboard (wl-copy)
#    - Copies the video file path to clipboard
#    - Install: sudo pacman -S wl-clipboard
#
# 5. notify-send (libnotify)
#    - Sends a desktop notification when recording ends
#    - Install: sudo pacman -S libnotify
#
# Notes:
# - The audio device for wf-recorder must be a valid monitor output
#   (use `pactl list sources | grep Name` to find one)
# - The script will:
#   1. Check if slurp is running
#   2. Create /tmp/videos if missing
#   3. Kill any running wf-recorder if found
#   4. Delete old sniprec.mp4
#   5. Let you select a region
#   6. Play start sound
#   7. Record the selected area
#   8. Copy the video path to clipboard
#   9. Play stop sound and send notification