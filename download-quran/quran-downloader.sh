#!/bin/bash

# Extract sheikh name & server base from URL
url="https://server16.mp3quran.net/a_binhameed/Rewayat-Hafs-A-n-Assem/006.mp3"

sheikh_name=$(echo "$url" | awk -F'/' '{print $(NF-1)}')
base_url=$(echo "$url" | sed 's/\/[^\/]*$//')

# Create folder & enter it
mkdir -p "$sheikh_name"
cd "$sheikh_name" || exit

# Download 114 surahs with check using wget
for i in {1..114}; do
  num=$(printf "%03d" "$i")
  file="${num}.mp3"

  # Check if file exists and is not empty
  if [ -s "$file" ]; then
    echo "Skipping $file - already downloaded."
  else
    echo "Downloading $file..."
    wget -c -q --show-progress "${base_url}/${file}"
  fi
done
