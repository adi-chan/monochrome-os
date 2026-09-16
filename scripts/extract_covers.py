#!/usr/bin/env python3
import os
import sys
import json
import hashlib
import subprocess

MUSIC_DIR = os.path.expanduser("~/Music")
CACHE_DIR = "/tmp/qs_art"
os.makedirs(CACHE_DIR, exist_ok=True)

def get_cover_for_file(rel_path):
    if not rel_path:
        return ""
    
    hash_str = hashlib.md5(rel_path.encode("utf-8")).hexdigest()
    out_img = os.path.join(CACHE_DIR, f"{hash_str}.jpg")

    if os.path.exists(out_img):
        return out_img

    full_path = os.path.join(MUSIC_DIR, rel_path)
    if not os.path.exists(full_path):
        return ""

    # Try extracting embedded artwork with ffmpeg
    try:
        res = subprocess.run(
            [
                "ffmpeg", "-v", "error", "-y",
                "-i", full_path,
                "-an", "-vframes", "1",
                "-vf", "scale=90:90:force_original_aspect_ratio=increase,crop=90:90",
                out_img
            ],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=2
        )
        if res.returncode == 0 and os.path.exists(out_img) and os.path.getsize(out_img) > 0:
            return out_img
    except Exception:
        pass

    # Fallback to directory cover image
    dir_path = os.path.dirname(full_path)
    if os.path.exists(dir_path):
        for candidate in ["cover.jpg", "cover.png", "folder.jpg", "folder.png", "album.jpg", "artwork.jpg"]:
            candidate_path = os.path.join(dir_path, candidate)
            if os.path.exists(candidate_path):
                try:
                    subprocess.run(
                        [
                            "ffmpeg", "-v", "error", "-y",
                            "-i", candidate_path,
                            "-vf", "scale=90:90:force_original_aspect_ratio=increase,crop=90:90",
                            "-vframes", "1",
                            out_img
                        ],
                        stdout=subprocess.DEVNULL,
                        stderr=subprocess.DEVNULL,
                        timeout=2
                    )
                    if os.path.exists(out_img) and os.path.getsize(out_img) > 0:
                        return out_img
                except Exception:
                    pass

    return ""

def main():
    try:
        raw_playlist = subprocess.check_output(
            ["mpc", "playlist", "-f", "%position%~~~%artist%~~~%title%~~~%time%~~~%file%"],
            text=True
        )
    except Exception as e:
        sys.exit(1)

    try:
        current_pos = subprocess.check_output(
            ["mpc", "current", "-f", "%position%"],
            text=True
        ).strip()
    except Exception:
        current_pos = ""

    lines = raw_playlist.strip().split("\n")
    results = []

    for idx, line in enumerate(lines):
        if not line.strip():
            continue
        parts = line.split("~~~")
        if len(parts) >= 5:
            pos = parts[0].strip() or str(idx + 1)
            artist = parts[1].strip()
            title = parts[2].strip()
            time_str = parts[3].strip()
            rel_file = parts[4].strip()
            is_playing = "1" if pos == current_pos else "0"

            cover_path = get_cover_for_file(rel_file)

            if not title and rel_file:
                title = os.path.splitext(os.path.basename(rel_file))[0]
            if not title:
                title = f"Track {pos}"
            if not artist:
                artist = "Unknown Artist"

            results.append({
                "pos": pos,
                "artist": artist,
                "title": title,
                "time": time_str,
                "file": rel_file,
                "cover": cover_path,
                "isPlaying": is_playing
            })

    print(json.dumps(results))

if __name__ == "__main__":
    main()
