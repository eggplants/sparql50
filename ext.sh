#!/bin/bash

c=0
ind=0
if ! [ -f "./SPARQL50.md" ]; then
  exit 1
fi

# shellcheck disable=SC2016
sed -n '/```rq/,/```/p'  SPARQL50.md |
  while IFS='' read -r i; do
    if [ "$i" = '```rq' ]; then
      c=1
      ((ind++))
      continue
    elif [ "$i" = '```' ]; then
      c=0
      continue
    fi
    [ "$c" = 1 ] && echo "$i" >> "$(printf "%02d.rq" "$ind")"
 done
