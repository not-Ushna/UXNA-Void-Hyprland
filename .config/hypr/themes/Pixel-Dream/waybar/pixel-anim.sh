#!/bin/bash

# Pacman animation
frames=(
  "ᗧ · · ·"
  "⍩⃝ · · ·"
  "ᗧ · ·  "
  "⍩⃝ · ·  "
  "ᗧ ·    "
  "⍩⃝ ·    "
  "ᗧ      "
  "⍩⃝      "
  "ᗣ      "
  "ᗣ ·    "
  "ᗣ · ·  "
  "ᗣ · · ·"
)

while true; do
  for frame in "${frames[@]}"; do
    echo "{\"text\": \"$frame\"}"
    sleep 0.3
  done
done
