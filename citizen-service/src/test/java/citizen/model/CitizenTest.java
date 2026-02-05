package citizen.model;

import jakarta.validation.ConstraintViolation;
import jakarta.validation.Validation;
import jakarta.validation.Validator;
import jakarta.validation.ValidatorFactory;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;

class CitizenTest {

    private Validator validator;

    @BeforeEach
    void setUp() {
        ValidatorFactory factory = Validation.buildDefaultValidatorFactory();
        validator = factory.getValidator();
    }

    @Test
    void testCitizenGettersSetters() {
        Citizen citizen = new Citizen();
        citizen.setAt("AZ123456");
        citizen.setFirstName("Γιάννης");
        citizen.setLastName("Παπαδόπουλος");

        assertThat(citizen.getAt()).isEqualTo("AZ123456");
        assertThat(citizen.getFirstName()).isEqualTo("Γιάννης");
    }

    @Test
    void testInvalidAtValidation() {
        Citizen citizen = new Citizen();
        citizen.setAt("123"); // Λάθος μήκος (πρέπει να είναι 8)
        citizen.setFirstName("Γιάννης");
        citizen.setLastName("Παπαδόπουλος");
        citizen.setGender("Άνδρας");

        Set<ConstraintViolation<Citizen>> violations = validator.validate(citizen);
        assertThat(violations).isNotEmpty();
        assertThat(violations.iterator().next().getMessage()).isEqualTo("Ο ΑΤ πρέπει να έχει 8 χαρακτήρες");
    }
}
