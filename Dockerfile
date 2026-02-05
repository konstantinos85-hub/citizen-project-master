# --- STAGE 1: Build Stage ---
FROM maven:3.9.9-eclipse-temurin-17-alpine AS build
WORKDIR /app

# 1. Αντιγραφή των αρχείων pom και ολόκληρων των modules
# (Απαραίτητο για να βλέπει το Maven τη δομή του project)
COPY pom.xml .
COPY citizen-domain/ citizen-domain/
COPY citizen-service/ citizen-service/
COPY citizen-client/ citizen-client/

# 2. Εκτέλεση του build σε ένα βήμα

RUN mvn clean package -DskipTests -pl citizen-service -am

# --- STAGE 2: Runtime Stage ---
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

# Δημιουργία μη προνομιούχου χρήστη για ασφάλεια
RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring

# Αντιγραφή του παραχθέντος JAR από το build stage
COPY --from=build /app/citizen-service/target/citizen-service-*.jar app.jar

# Έκθεση της θύρας (όπως ορίστηκε στο Terraform)
EXPOSE 8089

# Βέλτιστες ρυθμίσεις μνήμης για Java 17
ENTRYPOINT ["java", "-XX:+UseContainerSupport", "-XX:MaxRAMPercentage=75.0", "-jar", "app.jar", "--server.port=8089"]
