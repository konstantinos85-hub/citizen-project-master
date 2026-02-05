package citizen.repository;

import citizen.model.Citizen;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.test.context.TestPropertySource;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
// Εξασφαλίζει ότι το Spring θα χρησιμοποιήσει την H2 και θα δημιουργήσει αυτόματα τους πίνακες
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.ANY)
// Ρυθμίζει το Hibernate να δημιουργεί/διαγράφει το σχήμα ειδικά για αυτό το test
@TestPropertySource(properties = {
    "spring.jpa.hibernate.ddl-auto=create-drop",
    "spring.jpa.show-sql=true"
})
class CitizenRepositoryTest {

    @Autowired
    private CitizenRepository repository;

    @Test
    void testSaveAndFindCitizen() {
        // 1. Προετοιμασία (Setup)
        Citizen citizen = new Citizen();
        citizen.setAt("BT999999");
        citizen.setFirstName("Μαρία");
        citizen.setLastName("Δημητρίου");
        citizen.setGender("Γυναίκα");
        
        // 2. Εκτέλεση (Action)
        repository.save(citizen);

        // 3. Επαλήθευση (Verification)
        Citizen found = repository.findById("BT999999").orElse(null);
        
        assertThat(found).isNotNull();
        assertThat(found.getAt()).isEqualTo("BT999999");
        assertThat(found.getFirstName()).isEqualTo("Μαρία");
    }
}
