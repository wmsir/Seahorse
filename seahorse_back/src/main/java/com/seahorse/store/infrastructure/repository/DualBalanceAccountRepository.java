package com.seahorse.store.infrastructure.repository;

import com.seahorse.store.domain.member.model.DualBalanceAccount;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

@Repository
public interface DualBalanceAccountRepository extends JpaRepository<DualBalanceAccount, Long> {
    Optional<DualBalanceAccount> findByMemberId(Long memberId);
    List<DualBalanceAccount> findByMemberIdIn(Collection<Long> memberIds);
}
