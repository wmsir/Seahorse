package com.seahorse.store.infrastructure.repository;

import com.seahorse.store.domain.appointment.model.Appointment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface AppointmentRepository extends JpaRepository<Appointment, Long> {
    List<Appointment> findByStoreId(String storeId);
    List<Appointment> findByStoreIdAndAptDate(String storeId, String aptDate);
    List<Appointment> findByTenantId(String tenantId);
    Optional<Appointment> findByAptNo(String aptNo);
}
