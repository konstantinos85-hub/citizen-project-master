# Citizen Project (2025)

[![Citizen Project CI/CD Pipeline](github.com)](github.com)

## Περιγραφή
Αυτό το project υλοποιεί ένα ολοκληρωμένο σύστημα διαχείρισης πολιτών χωρισμένο σε τρεις υποφακέλους:
* **Client**: Διαδραστικός REST Client για τη διαχείριση δεδομένων.
* **Domain**: Μοντέλα δεδομένων και οντότητες (JPA Entities).
* **Service**: REST API Service για την επιχειρησιακή λογική.

## GitHub Actions Workflow
Ο αγωγός (pipeline) είναι ρυθμισμένος να εκτελείται αυτόματα σε κάθε push στο branch **develop**.
* **CI/CD**: Περιλαμβάνει checkout, μεταγλώττιση (Maven compile) και δοκιμές.
* **Testing**: Εκτελούνται Unit Tests και API/Integration Tests.
* **Artifacts**: Οι αναφορές των δοκιμών (Surefire/Failsafe reports) μεταφορτώνονται αυτόματα για οπτικοποίηση.
* **Releases**: Δημιουργείται αυτόματα μια πρώιμη έκδοση (Pre-release) με τα εκτελέσιμα αρχεία .jar.

## Οδηγίες Χρήσης
Για να τρέξετε το project τοπικά:
1. `mvn clean install` στη ρίζα του project.
2. Εκκίνηση του Service.
3. Εκκίνηση του Client.
