#!/bin/bash
# Nom : BAKKALI Yahya
# Matricule : 000445166

poolV1(){

    # Renvoie True si le pool V1 existe et crée le pool V2 s'il n'existe pas.
    # Sinon False

    if [ -d $1 ]
    # Pool V1 existe
    then

      echo "Chemin vers le pool V1 :" $1
      echo "Chemin vers le pool V2 :" $2
      echo "Photo admin ID :" $3
      echo "Photo group ID :" $4

      if [ ! -d $2 ]
      # Pool V2 n'existe pas
      then
        mkdir $2
        # Pool V2 n'existe pas on le crée
      fi
      chmod 750 $2
      chown $3:$4 $2
      # Désigner photo_admin comme propriétaire du pool V2
      # Fixer les permissions du répertoire
      return 0
    else
      echo "Pool V1 n'existe pas"
      # Pool V1 n'existe pas
      return 1
    fi
}

isUser(){

  # Renvoie True si l'utilisateur existe sur la machine sinon False

  if id "$1" >/dev/null 2>&1; then
        # Utilisateur existe
        return 0
  else
        # Utilisateur n'existe pas
        return 1
  fi
}

poolV1_to_poolV2(){

    # Fonction récursive permet la migration des fichiers du pool V1
    # vers le pool V2 et fixe les permissions des répertoires de pool V2
    # selon deux contraintes :
    # 1 - Les fichiers et répertoires de l’arborescence doivent être accessibles
    #     et lisibles par l’ensemble des utilisateurs du pool
    # 2 - Les fichiers et répertoires doivent être inaccessibles au reste
    #     des utilisateurs de la machine.

    for directory in $1/*
    # Pour chaque répertoire dans pool V1
    do
    if [ -d $directory ]
    # "directory" est un répertoire
    then
        poolV1_to_poolV2 $directory $2 $3 $4
        # Pour chaque sous-répertoire dans le répertoire "directory"
    else
        photoPATH=$directory
        # Le "PATH" de "directory" qui est un fichier photo
        dirPATH=${photoPATH%/*}
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

        mkdir -p -m 750 $2/$dirUSER
        # Créer le répertoire utilisateur
        chown $3:$4 $2/$dirUSER
        # Désigner photo admin comme propriétaire du répertoire

        photoName=${photoPATH##*/}
        # Nom du fichier en cours de traitement
        photoDate=${photoName%_*}
        # Date contenu dans le nom
        photoLS=($(ls -l $photoPATH))
        # Liste des informations sur la photo
        photoOwner=${photoLS[2]}
        # Le propriétaire de la photo
        echo "Déplacement de la photo :" $photoName
        # Extraire l'année , le mois et le jour de timestamp POSIX
        year=$(date +%Y -d @$photoDate)
        month=$(date +%m -d @$photoDate)
        day=$(date +%d -d @$photoDate)

        mkdir -p $2/$photoOwner/$year/$month/$day
        # Créer les répertoires (propriétaire-du-photo/année/mois/jour) dans pool V2
        dirOwner=$2/$photoOwner/
        dirYear=$2/$photoOwner/$year
        dirMonth=$2/$photoOwner/$year/$month
        newDirPATH=$2/$photoOwner/$year/$month/$day
        # Le nouveau "PATH" du répertoire qui contient le fichier photo dans pool V2
        chown $3:$4 $dirOwner $dirYear $dirMonth $newDirPATH
        # Désigner photo_admin comme propriétaire des répertoires (année/mois/jour)
        cp $photoPATH $newDirPATH
        # Copier la photo dans le pool V2
        newPhotoName=${photoName#*_}
        # Nouveau nom du photo dans le pool V2
        mv $newDirPATH/$photoName $newDirPATH/$newPhotoName
        # Renommer la photo
        chown $photoOwner:$4 $newDirPATH/$newPhotoName
        # Désigner le propriétaire du fichier photo
        chmod 750 $dirOwner $dirYear $dirMonth $newDirPATH $newDirPATH/$newPhotoName
        # Fixer les permissions des répertoires (propriétaire-du-photo/année/mois/jour)
        # Et du fichier photo

    fi
    done
}

canRunIt() {
  # Fonction pour effectuer un test sur l'utilisateur exécutant le script
  # Si l'exécutant n'a pas les permissions nécessaires pour exécuter
  # le script dans son intégralité, un message d'erreur est affiché et
  # le script retourne un code d'erreur. Autrement,le script est exécuté.

  userID=$(id -u)
  # L'utilisateur exécutant le script
  if [ "$userID" = "0" ]
  then
    # L'utilisateur exécutant le script est le superutilisateur
    # Donc le script est exécuté dans son intégralité
    return 0
  else
    echo "Permission non accordée pour exécuter le script"
    # Le script ne peut pas s'exécuter dans son intégralité
    exit 1
    # Retourne un code d'erreur
  fi
}

main() {
  canRunIt
  #Vérifier si le script peut s'exécuter
  if poolV1 $1 $2 $3 $4
  # Si le pool V1 existe on commence la migration
  then
      echo "Début de la migration du pool V1 vers le pool V2"
      poolV1_to_poolV2 $1 $2 $3 $4
      # Migration des fichiers photos du pool V1 vers le pool V2
      echo "Fin de la migration"
  fi

}

main $1 $2 $3 $4
