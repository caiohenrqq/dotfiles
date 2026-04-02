#!/usr/bin/env bash

case "$1" in
  *.jpg|*.jpeg|*.png|*.webp|*.gif)
    exiftool "$1"
    ;;
  *)
    file "$1"
    ;;
esac
