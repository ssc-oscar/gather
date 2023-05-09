#!/bin/bash

# Quick script to test each GH key in tokens file
input="tokens"
count=1

while read -r line
do
  # Debug
  # echo $line
  curl -v -H "Authorization: token $line" https://api.github.com/user/issues &> token_validity_$count
  let count++
done < "$input"

exit 0