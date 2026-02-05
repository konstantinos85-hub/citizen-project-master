package citizen.model;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

@Entity
public class Citizen {
    @Id
    @Pattern(regexp = "^[a-zA-Z0-9]{8}$", message = "Ο ΑΤ πρέπει να έχει 8 χαρακτήρες")
    private String at;

    @NotBlank(message = "Το όνομα είναι υποχρεωτικό")
    private String firstName;

    @NotBlank(message = "Το επίθετο είναι υποχρεωτικό")
    private String lastName;

    @NotBlank(message = "Το φύλο είναι υποχρεωτικό")
    private String gender;

    @Pattern(regexp = "^\\d{2}-\\d{2}-\\d{4}$", message = "Μορφή ημερομηνίας: ΧΧ-ΥΥ-ΚΚΚΚ")
    private String birthDate;

    @Pattern(regexp = "^(\\d{9})?$", message = "Το ΑΦΜ πρέπει να έχει 9 ψηφία")
    private String afm;

    private String address;

    
    public String getAt() { return at; }
    public void setAt(String at) { this.at = at; }
    public String getFirstName() { return firstName; }
    public void setFirstName(String firstName) { this.firstName = firstName; }
    public String getLastName() { return lastName; }
    public void setLastName(String lastName) { this.lastName = lastName; }
    public String getGender() { return gender; }
    public void setGender(String gender) { this.gender = gender; }
    public String getBirthDate() { return birthDate; }
    public void setBirthDate(String birthDate) { this.birthDate = birthDate; }
    public String getAfm() { return afm; }
    public void setAfm(String afm) { this.afm = afm; }
    public String getAddress() { return address; }
    public void setAddress(String address) { this.address = address; }
}
