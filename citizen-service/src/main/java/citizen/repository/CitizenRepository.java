package citizen.repository; 

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import citizen.model.Citizen;

@Repository
public interface CitizenRepository extends JpaRepository<Citizen, String> {
}


