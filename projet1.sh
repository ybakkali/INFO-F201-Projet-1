#!/bin/bash
echo $1




counter(){
    for file in "$1"/*
    do
    if [ -d "$file" ]
    then
        echo "$file"
        counter "$file"
    else

      echo "file name :" ${file##*/}
    fi
    done
}

counter "$1/Wallpaper"




if [ -d $1/Wallpaper ]; then
  # Control will enter here if $DIRECTORY doesn't exist.
  echo "NO"
fi
