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

createPoolV2(){
    for file in $1/*
    do
    if [ -d $file ]
    then
        echo $file
        createPoolV2 $file $2 $3 $4
    else
      image=${file##*/}
      imageDate=${image%_*}
      year=$(date +%Y -d @$imageDate)
      month=$(date +%m -d @$imageDate)
      day=$(date +%d -d @$imageDate)
      echo "file name :" $image
      mkdir -p $2/$year/$month/$day
      sudo chown $3:$4 $2/$year
      sudo chown $3:$4 $2/$year/$month
      sudo chown $3:$4 $2/$year/$month/$day
      sudo cp $file $2/$year/$month/$day
      sudo chown 1000:$4 $2/$year/$month/$day/$image
    fi
    done
}

createPoolV2 $1 $2 $3 $4
