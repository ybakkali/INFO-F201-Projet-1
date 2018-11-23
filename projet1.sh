#!/bin/bash
echo $1
echo $2
echo $3
echo $4

setRights() {

  # Fixe les permissions d'un fichier ou d'un dossier

  chmod u=wrx,g=rx,o=- $1
}

PoolV2(){

    # Renvoie True si le pool V1 existe et crée le pool V2 s'il n'existe pas.
    # Sinon False

    if [ -d $1 ]
    # Pool V1 existe
    then
      if [ -d $2 ]
      then
        # Pool V2 existe
        echo "Pool V2 existe"
      else
        mkdir $2
        # Crée le pool V2
        setRights $2
      fi
      return 0
    else
      # Pool V1 n'existe pas
      return 1
    fi
}

isUser(){

  # Renvoie True si l'utilisateur existe sur la machine sinon False

  if id "$1" >/dev/null 2>&1; then
        echo "Utilisateur $1 existe"
        return 0
  else
        echo "Utilisateur $1 n'existe pas"
        return 1
  fi
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

    # Fonction récursive qui permet la migration des fichiers du pool V1
    # vers le pool V2

    for directory in $1/*
    # Pour chaque répertoire dans pool V1
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
            # Le nom du répertoire personnel correspond
            # à un utilisateur existant sur la machine
        else
            dirLS=($(ls -ld $dirPATH ))
            # Liste des informations sur le répertoire
            dirUSER=${dirLS[2]}
            # Le propriétaire du répertoire personnel
        fi
        photoName=${directory##*/}
        # Nom du fichier en cours de traitement
        photoDate=${photoName%_*}
        # Date contenu dans le nom
        echo "Nom du fichier :" $photoName
        year=$(date +%Y -d @$photoDate)
        month=$(date +%m -d @$photoDate)
        day=$(date +%d -d @$photoDate)

        mkdir -p $2/$dirUSER/$year/$month/$day
        # Créer les répertoires (année/mois/jour)
        cp $directory $2/$dirUSER/$year/$month/$day
        # Copier la photo dans le pool V2
        newPhotoName=${photoName#*_}
        # Nouveau nom du photo dans pool V2
        mv $2/$dirUSER/$year/$month/$day/$photoName $2/$dirUSER/$year/$month/$day/$newPhotoName
        # Renommer la photo
    fi
    done
}

main() {
    if PoolV2 $1 $2
    then
        poolV1_to_poolV2 $1 $2 $3 $4
        setOwner $2 $3 $4
        chown $3:$4 $2
        ls -l -R $2
    fi
}

main $1 $2 $3 $4
