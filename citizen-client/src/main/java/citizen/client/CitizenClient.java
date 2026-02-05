package citizen.client;

import citizen.model.Citizen;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Profile;
import org.springframework.http.client.HttpComponentsClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;
import java.util.Scanner;
import org.springframework.beans.factory.annotation.Value;


@Profile("client")
@Component // ΕΝΕΡΓΟΠΟΙΗΜΕΝΟ: Πλέον το Spring αναγνωρίζει την κλάση
@ConditionalOnProperty(name = "citizen.client.enabled", havingValue = "true", matchIfMissing = true)
public class CitizenClient implements CommandLineRunner {

    @Value("${citizen.api.url}")
    private String BASE_URL;
    private final RestTemplate restTemplate;

    public CitizenClient() {
        // Υποστήριξη Apache HttpClient για PATCH requests
        this.restTemplate = new RestTemplate(new HttpComponentsClientHttpRequestFactory());
    }

    @Override
    public void run(String... args) {
        // ΕΛΕΓΧΟΣ ΠΕΡΙΒΑΛΛΟΝΤΟΣ: Αν τρέχει σε GitHub Actions ή χωρίς τερματικό (Terraform), σταματάει εδώ.
        if (System.getenv("GITHUB_ACTIONS") != null || System.console() == null) {
            System.out.println("====================================================");
            System.out.println("CI/CD Environment detected (GitHub/Terraform).");
            System.out.println("Skipping interactive menu to prevent crash.");
            System.out.println("====================================================");
            return; 
        }
        
        startInteractiveMenu();
    }

    private void startInteractiveMenu() {
        Scanner scanner = new Scanner(System.in);
        boolean running = true;
        System.out.println("======================================");
        System.out.println("   ΜΕΝΟΥ ΔΙΑΧΕΙΡΙΣΗΣ ΠΟΛΙΤΩΝ (2025)   ");
        System.out.println("======================================");
        
        while (running) {
            try {
                System.out.println("\n1. Προβολή όλων των πολιτών");
                System.out.println("2. Αναζήτηση πολίτη με ΑΤ");
                System.out.println("3. Εισαγωγή νέου πολίτη (POST)");
                System.out.println("4. Ενημέρωση διεύθυνσης/ΑΦΜ (PATCH)");
                System.out.println("5. Διαγραφή πολίτη (DELETE)");
                System.out.println("--------------------------------------");
                System.out.print("Επιλογή (Οποιαδήποτε άλλη για έξοδο): ");

                // Δεύτερη δικλείδα ασφαλείας για τον Scanner
                if (!scanner.hasNextLine()) {
                    break;
                }
                
                String choice = scanner.nextLine().trim();

                switch (choice) {
                    case "1" -> listAll();
                    case "2" -> getByAt(scanner);
                    case "3" -> create(scanner);
                    case "4" -> update(scanner);
                    case "5" -> delete(scanner);
                    default -> {
                        System.out.println("Τερματισμός εφαρμογής...");
                        running = false;
                    }
                }
            } catch (Exception e) {
                System.err.println("Σφάλμα κατά την εκτέλεση: " + e.getMessage());
            }
        }
    }

    private void listAll() {
        try {
            Citizen[] citizens = restTemplate.getForObject(BASE_URL + "/search", Citizen[].class);
            if (citizens != null && citizens.length > 0) {
                for (Citizen c : citizens) {
                    System.out.println(c.getAt() + " - " + c.getFirstName() + " " + c.getLastName());
                }
            } else {
                System.out.println("Δεν βρέθηκαν πολίτες.");
            }
        } catch (Exception e) {
            System.out.println("Σφάλμα σύνδεσης με το API.");
        }
    }

    private void getByAt(Scanner scanner) {
        System.out.print("Εισάγετε ΑΤ: ");
        String at = scanner.nextLine();
        try {
            Citizen c = restTemplate.getForObject(BASE_URL + "/" + at, Citizen.class);
            if (c != null) {
                System.out.println("Βρέθηκε: " + c.getFirstName() + " " + c.getLastName() + " (ΑΦΜ: " + c.getAfm() + ")");
            }
        } catch (Exception e) {
            System.out.println("Ο πολίτης με ΑΤ " + at + " δεν βρέθηκε.");
        }
    }

    private void create(Scanner scanner) {
        try {
            Citizen c = new Citizen();
            System.out.print("ΑΤ: "); c.setAt(scanner.nextLine());
            System.out.print("Όνομα: "); c.setFirstName(scanner.nextLine());
            System.out.print("Επίθετο: "); c.setLastName(scanner.nextLine());
            System.out.print("Φύλο: "); c.setGender(scanner.nextLine());
            System.out.print("ΑΦΜ: "); c.setAfm(scanner.nextLine());
            
            restTemplate.postForObject(BASE_URL, c, Citizen.class);
            System.out.println("Ο πολίτης εισήχθη επιτυχώς.");
        } catch (Exception e) {
            System.out.println("Αποτυχία εισαγωγής: " + e.getMessage());
        }
    }

    private void update(Scanner scanner) {
        try {
            System.out.print("Εισάγετε το ΑΤ του πολίτη για ενημέρωση: ");
            String at = scanner.nextLine();
            Citizen update = new Citizen();
            System.out.print("Νέα Διεύθυνση: "); update.setAddress(scanner.nextLine());
            System.out.print("Νέο ΑΦΜ (προαιρετικά): "); update.setAfm(scanner.nextLine());
            
            restTemplate.patchForObject(BASE_URL + "/" + at, update, String.class);
            System.out.println("Η ενημέρωση (PATCH) ολοκληρώθηκε.");
        } catch (Exception e) {
            System.out.println("Αποτυχία ενημέρωσης.");
        }
    }

    private void delete(Scanner scanner) {
        try {
            System.out.print("Εισάγετε ΑΤ για διαγραφή: ");
            String at = scanner.nextLine();
            restTemplate.delete(BASE_URL + "/" + at);
            System.out.println("Ο πολίτης διαγράφηκε επιτυχώς.");
        } catch (Exception e) {
            System.out.println("Αποτυχία διαγραφής.");
        }
    }
}

