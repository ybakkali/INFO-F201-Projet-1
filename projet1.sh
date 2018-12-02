#!/bin/bash
# Nom : BAKKALI Yahya
# Matricule : 000445166
echo "Chemin vers pool V1 :" $1
echo "Chemin vers pool V2 :" $2
echo "Photo admin uid :" $3
echo "Photo group gid" $4

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
        mkdir -m 750 $2
        # Pool V2 n'existe pas on le crée
        chown $3:$4 $2
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

    # Fonction récursive permet la migration des fichiers du pool V1
    # vers le pool V2 et fixe les permissions des répertoires de pool V2
    # selon deux contraintes :
    #   1 - Les fichiers et répertoires de l’arborescence doivent être accessibles
    #       et lisibles par l’ensemble des utilisateurs du pool
    #   2 - Les fichiers et répertoires doivent être inaccessibles au reste
    #       des utilisateurs de la machine.

    for directory in $1/*
    # Pour chaque répertoire dans pool V1
    do
    if [ -d $directory ]
    # Si "directory" est un répertoire
    then
        poolV1_to_poolV2 $directory $2 $3 $4
        # Pour chaque sous-répertoire dans le répertoire "directory"
    else
        photoPAtH=$directory
        # Sinon "directory" est un fichier photo
        dirPATH=${photoPAtH%/*}
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
            # Le propriétaire du répertoire personnel en cours de traitement
        fi
        photoName=${photoPAtH##*/}
        # Nom du fichier en cours de traitement
        photoDate=${photoName%_*}
        # Date contenu dans le nom
        photoLS=($(ls -l $photoPAtH))
        # Liste des informations sur la photo
        photoOwner=${photoLS[2]}
        # Le propriétaire de la photo
        echo "Nom du fichier :" $photoName
        # Extraire l'année , le mois et le jour de timestamp POSIX
        year=$(date +%Y -d @$photoDate)
        month=$(date +%m -d @$photoDate)
        day=$(date +%d -d @$photoDate)

        if [ ! -d $2/$dirUSER ]
        then
          mkdir -m 750 $2/$dirUSER
          # Créer le répertoire utilisateur
          chown $3:$4 $2/$dirUSER
          # Désigner photo_admin comme propriétaire du répertoire
        fi

        mkdir -p $2/$photoOwner/$year/$month/$day
        # Créer les répertoires (année/mois/jour)
        dir1=$2/$photoOwner/
        dir2=$2/$photoOwner/$year
        dir3=$2/$photoOwner/$year/$month
        dir4=$2/$photoOwner/$year/$month/$day
        chown $3:$4 $dir1 $dir2 $dir3 $dir4
        chmod 750 $dir1 $dir2 $dir3 $dir4
        # Désigner photo_admin comme propriétaire des répertoires (année/mois/jour)

        cp -p $photoPAtH $2/$photoOwner/$year/$month/$day
        # Copier la photo dans le pool V2
        newPhotoName=${photoName#*_}
        # Nouveau nom du photo dans le pool V2
        mv $2/$photoOwner/$year/$month/$day/$photoName $2/$photoOwner/$year/$month/$day/$newPhotoName
        # Renommer la photo
        chgrp $4 $2/$photoOwner/$year/$month/$day/$newPhotoName
        chmod 750 $2/$photoOwner/$year/$month/$day/$newPhotoName
    fi
    done
}

main() {
    if poolV1 $1 $2 $3 $4
    # Si le pool V1 existe on commence la migration
    then
        poolV1_to_poolV2 $1 $2 $3 $4
        # Migration des fichiers photo du pool V1 vers pool V2
        #ls -l -R $2
    fi
}

main $1 $2 $3 $4
