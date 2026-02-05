package citizen.controller;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import citizen.model.Citizen;
import citizen.repository.CitizenRepository;

import java.util.List; 


@RestController
@CrossOrigin(origins = "*") // Επιτρέπει κλήσεις από οποιοδήποτε origin (χρήσιμο για δοκιμές)
@RequestMapping("/api/citizens")
public class CitizenController {

    @Autowired
    private CitizenRepository repository;

    // 1. Δοκιμή: Πηγαίνετε στο http://localhost:8089/api/citizens/test
    @GetMapping("/test")
    public String test() {
        return "Το API λειτουργεί κανονικά!";
    }

    // 2. Αναζήτηση: http://localhost:8089/api/citizens/search
    @GetMapping("/search")
    public List<Citizen> search(
            @RequestParam(required = false) String firstName,
            @RequestParam(required = false) String lastName,
            @RequestParam(required = false) String afm) {
        return repository.findAll(); 
    }

    // 3. Εύρεση με ΑΤ: http://localhost:8089/api/citizens/AZ123456
    
    @GetMapping("/{at}")
    public ResponseEntity<?> getCitizen(@PathVariable String at) { 
        return repository.findById(at)
                .<ResponseEntity<?>>map(citizen -> ResponseEntity.ok(citizen))
                .orElse(ResponseEntity.status(404).body("Ο πολίτης δεν βρέθηκε."));
    }

    // 4. Εισαγωγή (POST)
    @PostMapping
    public ResponseEntity<?> create(@Valid @RequestBody Citizen citizen) {
        if (repository.existsById(citizen.getAt())) {
            return ResponseEntity.badRequest().body("Η εγγραφή με αυτόν τον ΑΤ υπάρχει ήδη.");
        }
        return ResponseEntity.ok(repository.save(citizen));
    }

    // 5. Διαγραφή (DELETE)
    @DeleteMapping("/{at}")
    public ResponseEntity<?> delete(@PathVariable String at) {
        if (at == null || at.length() != 8) {
            return ResponseEntity.badRequest().body("Λανθασμένος ή κενός ΑΤ.");
        }
        if (!repository.existsById(at)) {
            return ResponseEntity.status(404).body("Ο πολίτης δεν βρέθηκε.");
        }
        repository.deleteById(at);
        return ResponseEntity.ok("Η διαγραφή ολοκληρώθηκε επιτυχώς.");
    }

    // 6. Ενημέρωση (PATCH)
    @PatchMapping("/{at}")
    public ResponseEntity<?> update(@PathVariable String at, @RequestBody Citizen updateData) {
        return repository.findById(at).map(citizen -> {
            if (updateData.getAfm() != null && !updateData.getAfm().matches("\\d{9}")) {
                return ResponseEntity.badRequest().body("Το ΑΦΜ πρέπει να έχει 9 ψηφία.");
            }
            if (updateData.getAfm() != null) citizen.setAfm(updateData.getAfm());
            if (updateData.getAddress() != null) citizen.setAddress(updateData.getAddress());
            
            repository.save(citizen);
            return ResponseEntity.ok("Η ενημέρωση ολοκληρώθηκε.");
        }).orElse(ResponseEntity.status(404).body("Ο πολίτης δεν βρέθηκε."));
    }
}

    

    
    
