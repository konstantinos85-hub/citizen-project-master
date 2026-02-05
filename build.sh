#!/bin/bash

# 1. Ορισμός ονόματος εικόνας
IMAGE_NAME="citizen-service-app"
VOLUME_NAME="citizen_db_data"

echo "--- Ξεκινά η διαδικασία Build για την υπηρεσία Citizen Registry ---"

# 2. Δημιουργία Docker Volume για την επίμονη αποθήκευση της MySQL
# Ελέγχει αν υπάρχει ήδη, αν όχι το δημιουργεί.
if [ $(docker volume ls -q -f name=^${VOLUME_NAME}$) ]; then
    echo "Το Volume '${VOLUME_NAME}' υπάρχει ήδη."
else
    echo "Δημιουργία Docker Volume: ${VOLUME_NAME}..."
    docker volume create ${VOLUME_NAME}
fi

# 3. Δημιουργία της Docker εικόνας (Image) της RESTful υπηρεσίας
# Χρησιμοποιεί το Dockerfile που βρίσκεται στον τρέχοντα φάκελο (.)
echo "Δημιουργία Docker Image: ${IMAGE_NAME}..."
docker build -t ${IMAGE_NAME} .

echo "--- Η διαδικασία ολοκληρώθηκε επιτυχώς! ---"
echo "Μπορείτε να δείτε την εικόνα σας με την εντολή: docker images"
