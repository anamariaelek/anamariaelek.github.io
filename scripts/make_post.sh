#!/bin/bash

# Check if a directory argument is provided
if [ -z "$2" ]; then
  echo "Usage: $0 <directory> $1 <title>"
  exit 1
fi

directory="$1"
title="$3"
output_file="${directory}.md"
base_url="https://anamaria-elek-hr.s3.eu-central-1.amazonaws.com/${directory}"

echo "---" > "$output_file"
echo "layout: post" >> "$output_file"
echo "title: $title" >> "$output_file"
echo "date: 2024-08-20" >> "$output_file"
echo "s3-base: $base_url" >> "$output_file"
echo "images:" >> "$output_file"

# Iterate through the subfolders and images
for type in horizontal vertical pano; do
  folder="$directory/sized/$type"
  if [ -d "$folder" ]; then
    for image in "$folder"/*.jpg; do
      if [ -f "$image" ]; then
        image_id=$(basename "$image" .jpg)
        echo "  - type: $type" >> "$output_file"
        echo "    id: $image_id" >> "$output_file"
      fi
    done
  fi
done

echo "---" >> "$output_file"

echo "Markdown file generated: $output_file"