#!/bin/bash
echo $1
echo $2
echo $3
echo $4

PoolV2(){
    if [ -d $1 ]
    then
      if [ -d $2 ]
      then
        echo "OK"
      else
        mkdir $2
        sudo chown $3:$4 $2
        sudo chmod u=wrx,g=rx,o=- $2
      fi
    fi
}

isUser(){
  if id "$1" >/dev/null 2>&1; then
        echo "user exists"
        return 0
  else
        echo "user does not exist"
        return 1
  fi
}

setRights() {
  sudo chmod u=wrx,g=rx,o=- $1
}
setOwner() {
  for directory in $1/*
  do
  if [ -d $directory ]
  then
      sudo chown $2:$3 $directory
      setRights $directory
      ls -l $directory
      setOwner $directory $2 $3
  else
      currentDir=${directory##*v2/}
      dirName=${currentDir%%/*}
      sudo chown $dirName:$3 $directory
      setRights $directory
      ls -l $directory
  fi
  done
}
poolV1_to_poolV2(){
    #For directory in pool v1
    for directory in $1/*
    do
    if [ -d $directory ]
    then
        echo $directory
        poolV1_to_poolV2 $directory $2 $3 $4
    else
        #Directory name
        currentDir=${directory%/*}
        dirName=${currentDir##*/}
        if isUser $dirName
        then
            dirUSER=$dirName
        else
            #Directory User
            dirPATH=${directory%/*}
            dirLS=($(ls -ld $dirPATH ))
            dirUSER=${dirLS[2]}
        fi
        echo $dirName $dirUSER

        #File
        photo=${directory##*/}
        photoDate=${photo%_*}
        year=$(date +%Y -d @$photoDate)
        month=$(date +%m -d @$photoDate)
        day=$(date +%d -d @$photoDate)
        echo "file name :" $photo

        #Create directories (year/month/day)
        mkdir -p $2/$dirUSER/$year/$month/$day


        #Directories rights
        #sudo chown $3:$4 $2/$dirUSER
        #sudo chown $3:$4 $2/$dirUSER/$year
        #sudo chown $3:$4 $2/$dirUSER/$year/$month
        #sudo chown $3:$4 $2/$dirUSER/$year/$month/$day
        #setRights $2/$dirUSER $2/$dirUSER/$year $2/$dirUSER/$year/$month $2/$dirUSER/$year/$month/$day

        #Copy the photo to the pool v2
        cp $directory $2/$dirUSER/$year/$month/$day
        newPhotoName=${photo#*_}
        mv $2/$dirUSER/$year/$month/$day/$photo $2/$dirUSER/$year/$month/$day/$newPhotoName
        
        #sudo chown $dirUSER:$4 $2/$dirUSER/$year/$month/$day/$photo
        #sudo chmod u=wrx,g=rx,o=- $2/$dirUSER/$year/$month/$day/$photo
    fi
    done
}
main() {
    PoolV2 $1 $2
    poolV1_to_poolV2 $1 $2 $3 $4
    setOwner $2 $3 $4
}

main $1 $2 $3 $4
