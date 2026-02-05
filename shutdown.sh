#!/bin/bash

# Ορισμός μεταβλητών (πρέπει να ταυτίζονται με το startup.sh)
NETWORK_NAME="citizen-network"
DB_CONTAINER="citizen-db"
APP_CONTAINER="citizen-app"

echo "--- Έναρξη Διαδικασίας Τερματισμού (shutdown.sh) ---"

# 1. Σταμάτημα και Καταστροφή των δοχείων (Containers)
echo "Σταμάτημα και αφαίρεση των δοχείων ${APP_CONTAINER} και ${DB_CONTAINER}..."
docker stop ${APP_CONTAINER} ${DB_CONTAINER} 2>/dev/null
docker rm ${APP_CONTAINER} ${DB_CONTAINER} 2>/dev/null

# 2. Καταστροφή του οριζόμενου από το χρήστη δικτύου (Network)
echo "Αφαίρεση του δικτύου ${NETWORK_NAME}..."
docker network rm ${NETWORK_NAME} 2>/dev/null

# 3. Καθαρισμός ενδιάμεσων εικόνων (Dangling Images)
# Διαγράφει εικόνες που έμειναν χωρίς "tag" κατά τη διαδικασία του build (ενδιάμεσες φάσεις)
echo "Καθαρισμός ενδιάμεσων και ανώνυμων εικόνων Docker..."
docker image prune -f

echo "--- Ο τερματισμός ολοκληρώθηκε επιτυχώς! ---"
echo "Σημείωση: Ο επίμονος αποθηκευτικός χώρος (Volume) διατηρήθηκε."
