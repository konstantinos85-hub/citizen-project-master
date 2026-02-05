package citizen.controller;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.*;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.test.context.ActiveProfiles;

import citizen.model.Citizen;
import io.restassured.RestAssured;
import io.restassured.http.ContentType;

/**
 * API/Integration Test για την οντότητα Citizen.
 * Εκτελείται αυτόματα από το maven-failsafe-plugin κατά τη φάση verify του αγωγού.
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test") // Ενεργοποιεί το profile 'test' για να μην παγώσει ο αγωγός στο μενού
public class CitizenIT {

    // Η σωστή annotation για το 2025 που επιλύει το σφάλμα resolution της θύρας
    @LocalServerPort
    private int port;

    @BeforeEach
    public void setUp() {
        // Ρύθμιση του RestAssured να "χτυπάει" τη δυναμική θύρα του server
        RestAssured.port = port;
        RestAssured.basePath = "/api/citizens";
    }

    @Test
    public void testCreateAndGetCitizen() {
        // 1. Προετοιμασία δεδομένων για τη δοκιμή API
        Citizen citizen = new Citizen();
        citizen.setAt("AZ123456");
        citizen.setFirstName("Konstantinos");
        citizen.setLastName("Kouyouris");
        citizen.setGender("Male");
        citizen.setAfm("123456789");
        citizen.setBirthDate("01-01-1990");
        citizen.setAddress("Athens 123");

        // 2. Δοκιμή POST (Δημιουργία Πολίτη)
        given()
            .contentType(ContentType.JSON)
            .body(citizen)
        .when()
            .post()
        .then()
            .statusCode(anyOf(is(200), is(201))) // Δέχεται status 200 ή 201
            .body("at", equalTo("AZ123456"))
            .body("firstName", equalTo("Konstantinos"));

        // 3. Δοκιμή GET (Ανάκτηση του Πολίτη που μόλις δημιουργήθηκε)
        given()
            .pathParam("at", "AZ123456")
        .when()
            .get("/{at}")
        .then()
            .statusCode(200)
            .body("lastName", equalTo("Kouyouris"))
            .body("afm", equalTo("123456789"));
    }
}
