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
    for directory in $1/*
    do
    if [ -d $directory ]
    then
        echo $directory
        createPoolV2 $directory $2 $3 $4
    else
        #Directory User
        dirPATH=${directory%/*}
        dirLS=($(ls -ld $dirPATH ))
        dirUSER=${dirLS[2]}
        echo $dirUSER
        #File
        image=${directory##*/}
        imageDate=${image%_*}
        year=$(date +%Y -d @$imageDate)
        month=$(date +%m -d @$imageDate)
        day=$(date +%d -d @$imageDate)
        echo "file name :" $image
        #Create directories (year/month/day)
        mkdir -p $2/$year/$month/$day
        #Directories rights
        sudo chown $3:$4 $2/$year
        sudo chown $3:$4 $2/$year/$month
        sudo chown $3:$4 $2/$year/$month/$day
        sudo cp $directory $2/$year/$month/$day
        sudo chown $3:$4 $2/$year/$month/$day/$image
    fi
    done
}

createPoolV2 $1 $2 $3 $4
