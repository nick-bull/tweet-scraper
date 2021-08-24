#!/bin/sh

for i; do
  echo "### Beginning to scrape tweets from '$i' to '$i.txt'"
  ./run.sh "$i" "$i.txt"
done
