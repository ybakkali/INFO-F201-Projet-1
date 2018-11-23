#!/bin/bash
echo $1
echo $2
echo $3
echo $4

PoolV2(){

    # Vérifie que si le pool V1 existe

    if [ -d $1 ]
    then
      if [ -d $2 ]
      then
        echo "OK"
      else
        mkdir $2
      fi
      return 0
    else
      return 1
    fi
}

isUser(){

  # Renvoie True si l'utilisateur existe sur la machine sinon False

  if id "$1" >/dev/null 2>&1; then
        echo "user exists"
        return 0
  else
        echo "user does not exist"
        return 1
  fi
}

setRights() {

  # Fixe les permissions d'un fichier ou d'un dossier

  chmod u=wrx,g=rx,o=- $1
}

setOwner() {

  # Fixe récursivement le propriétaire et le groupe
  # associé à un fichier ou à un dossier dans le pool V2

  for directory in $1/*
  do
  if [ -d $directory ]
  then
      chown $2:$3 $directory
      setOwner $directory $2 $3
      setRights $directory
  else
      currentDir=${directory##*v2/}
      dirName=${currentDir%%/*}
      chown $dirName:$3 $directory
      setRights $directory
  fi
  done
}
poolV1_to_poolV2(){

    # Fonction qui permet la migration des fichiers du pool V1 vers le pool V2

    # Pour chaque répertoire du pool v1
    for directory in $1/*
    do
    if [ -d $directory ]
    then
        poolV1_to_poolV2 $directory $2 $3 $4
    else
        dirPATH=${directory%/*}
        # "PATH" vers le répertoire courant
        dirName=${dirPATH##*/}
        # Nom du répertoire personnel en cours de traitement

        if isUser $dirName
        then
            dirUSER=$dirName
        else
            dirLS=($(ls -ld $dirPATH ))
            # Liste des informations sur le répertoire
            dirUSER=${dirLS[2]}
            # Le propriétaire du répertoire personnel
        fi

        # Nom du fichier en cours de traitement
        photoName=${directory##*/}
        photoDate=${photoName%_*}
        year=$(date +%Y -d @$photoDate)
        month=$(date +%m -d @$photoDate)
        day=$(date +%d -d @$photoDate)
        echo "file name :" $photoName

        # Créer les répertoires (année/mois/jour)
        mkdir -p $2/$dirUSER/$year/$month/$day

        #Directories rights
        #chown $3:$4 $2/$dirUSER $2/$dirUSER/$year $2/$dirUSER/$year/$month $2/$dirUSER/$year/$month/$day
        #setRights $2/$dirUSER $2/$dirUSER/$year $2/$dirUSER/$year/$month $2/$dirUSER/$year/$month/$day

        cp $directory $2/$dirUSER/$year/$month/$day
        # Copier la photo dans le pool v2
        newPhotoName=${photoName#*_}
        mv $2/$dirUSER/$year/$month/$day/$photoName $2/$dirUSER/$year/$month/$day/$newPhotoName
        # Renommer la photo

        #chown $dirUSER:$4 $2/$dirUSER/$year/$month/$day/$photoName
        #chmod u=wrx,g=rx,o=- $2/$dirUSER/$year/$month/$day/$photoName
    fi
    done
}
main() {
    if PoolV2 $1 $2
        poolV1_to_poolV2 $1 $2 $3 $4
        setOwner $2 $3 $4
        ls -l -R $2
        chown $3:$4 $2
        chmod u=wrx,g=rx,o=- $2
    fi
}

main $1 $2 $3 $4
