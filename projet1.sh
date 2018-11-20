#!/bin/bash
echo $1
echo $2
echo $3
echo $4

if [ -d $1 ]
then
  if [ -d $2 ]
  then
    echo "OK"
  else
    mkdir $2
  fi
fi
counter(){
    for file in $1/*
    do
    if [ -d $file ]
    then
        echo $file
        counter $file
    else
      echo "file name :" ${file##*/}
    fi
    done
}

counter $1
