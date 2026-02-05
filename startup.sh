#!/bin/bash

# Ορισμός μεταβλητών
NETWORK_NAME="citizen-network"
DB_CONTAINER="citizen-db"
APP_CONTAINER="citizen-app"
DB_IMAGE="mysql:8.0"
APP_IMAGE="citizen-service-app"
VOLUME_NAME="citizen_db_data"

echo "--- Έναρξη Διάταξης Backend (startup.sh) ---"

# Διαγράφει τα δοχεία αν υπάρχουν ήδη, για να αποφευχθεί το σφάλμα Conflict
docker rm -f ${DB_CONTAINER} ${APP_CONTAINER} 2>/dev/null || true

# 1. Δημιουργία οριζόμενου από το χρήστη δικτύου (User-defined Bridge Network)
# Επιτρέπει την επικοινωνία μέσω ονομάτων (Service Discovery) αντί localhost
docker network create ${NETWORK_NAME} 2>/dev/null || true

# 2. Εκκίνηση του δοχείου ΣΔΒΔ (MySQL)
# -v: Αντιστοίχιση του volume με τον φάκελο δεδομένων /var/lib/mysql
# Δημιουργία μη-ριζικού χρήστη (MYSQL_USER) και βάσης (MYSQL_DATABASE)
# Σημείωση: ΔΕΝ εκθέτουμε την 3306 στο host για λόγους ασφαλείας (πρόσβαση μόνο εντός δικτύου)
echo "Εκκίνηση δοχείου MySQL με επίμονο αποθηκευτικό χώρο..."
docker run -d \
  --name ${DB_CONTAINER} \
  --network ${NETWORK_NAME} \
  --restart always \
  -e MYSQL_DATABASE=citizen \
  -e MYSQL_USER=appuser \
  -e MYSQL_PASSWORD=citizen123 \
  -e MYSQL_ROOT_PASSWORD=root_secure_pass \
  -v ${VOLUME_NAME}:/var/lib/mysql \
  ${DB_IMAGE}

# 3. Αναμονή για την προετοιμασία του ΣΔΒΔ
echo "Αναμονή 20 δευτερολέπτων για τη διαμόρφωση της βάσης..."
sleep 20

# 4. Εκκίνηση του δοχείου της RESTful υπηρεσίας
# Χρήση του ονόματος "citizen-db" στο host της βάσης
# Εκθέτουμε ΜΟΝΟ την πόρτα 8089 στο τοπικό σύστημα
echo "Εκκίνηση δοχείου RESTful υπηρεσίας..."
docker run -d \
  --name ${APP_CONTAINER} \
  --network ${NETWORK_NAME} \
  -e DB_HOST=${DB_CONTAINER} \
  -e DB_NAME=citizen \
  -e DB_USER=appuser \
  -e DB_PASSWORD=citizen123 \
  -p 8089:8089 \
  ${APP_IMAGE}

echo "--- Η διάταξη ολοκληρώθηκε! ---"
echo "Πρόσβαση στην υπηρεσία: http://localhost:8089/api/citizens/test"
