package com.seahorse.store.infrastructure.repository;

import com.seahorse.store.domain.iam.model.IdentityBinding;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface IdentityBindingRepository extends JpaRepository<IdentityBinding, Long> {
    Optional<IdentityBinding> findFirstByOneidSubOrderByIdAsc(String oneidSub);
    List<IdentityBinding> findByOneidSub(String oneidSub);
    Optional<IdentityBinding> findByEmployeeId(Long employeeId);
}
