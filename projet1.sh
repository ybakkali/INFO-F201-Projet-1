#!/bin/bash
echo $1
echo $2
echo $3
echo $4

setRights() {

  # Fixe les permissions d'un fichier ou d'un dossier selon deux contraintes :
  # 1 - Les fichiers et répertoires de l’arborescence doivent être accessibles
  #     et lisibles par l’ensemble des utilisateurs du pool
  # 2 - Les fichiers et répertoires doivent être inaccessibles au reste
  #     des utilisateurs de la machine.

  chmod u=wrx,g=rx,o=- $1
}

poolV1(){

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
        # Pool V2 n'existe pas on le crée
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

poolV1_to_poolV2(){

    # Fonction récursive qui permet la migration des fichiers du pool V1
    # vers le pool V2

    for directory in $1/*
    # Pour chaque répertoire dans pool V1
    do
    if [ -d $directory ]
    # Si "directory" est un répertoire
    then
        poolV1_to_poolV2 $directory $2 $3 $4
        # Pour chaque sous-répertoire dans le répertoire "directory"
    else
        # Sinon "directory" est une photo
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
        photoLS=($(ls -l $directory))
        # Liste des informations sur la photo
        photoOwner=${photoLS[2]}
        # Le propriétaire de la photo
        echo "Nom du fichier :" $photoName
        year=$(date +%Y -d @$photoDate)
        month=$(date +%m -d @$photoDate)
        day=$(date +%d -d @$photoDate)

        mkdir -p $2/$dirUSER/$year/$month/$day
        # Créer les répertoires (utilisateur/année/mois/jour)
        cp $directory $2/$photoOwner/$year/$month/$day
        # Copier la photo dans le pool V2
        newPhotoName=${photoName#*_}
        # Nouveau nom du photo dans pool V2
        mv $2/$photoOwner/$year/$month/$day/$photoName $2/$photoOwner/$year/$month/$day/$newPhotoName
        # Renommer la photo
    fi
    done
}

setOwner() {

  # Désigne récursivement le propriétaire et le groupe
  # associé à un fichier photo ou à un dossier dans le pool V2

  for directory in $1/*
  # Pour chaque répertoire dans pool V1
  do
  if [ -d $directory ]
  then
      chown $2:$3 $directory
      # Désigner photo_admin comme propriétaire du répertoire
      setOwner $directory $2 $3
      # Pour chaque sous-répertoire dans le répertoire "directory"
      setRights $directory
      # Rendre le répertoire inaccessible au reste
      # des utilisateurs de la machine
  else
      currentDir=${directory##*v2/}
      # "PATH" vers le répertoire courant
      dirName=${currentDir%%/*}
      # Nom du répertoire
      chown $dirName:$3 $directory
      # Désigner l’actuel propriétaire du fichier photo
      # comme nouveau propriétaire
      setRights $directory
      # Rendre le fichier photo inaccessible au reste
      # des utilisateurs de la machine
  fi
  done
}
main() {
    if poolV1 $1 $2
    # Si le pool V1 existe on commence la migration
    then
        poolV1_to_poolV2 $1 $2 $3 $4
        # Migration des fichiers photo du pool V1 vers pool V2
        setOwner $2 $3 $4
        # Désigner les propriétaire
        chown $3:$4 $2
        setRights $2
        ls -l -R $2
    fi
}

main $1 $2 $3 $4
