package com.seahorse.store.infrastructure.repository;

import com.seahorse.store.domain.member.model.Member;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

@Repository
public interface MemberRepository extends JpaRepository<Member, Long> {
    boolean existsByMemberNo(String memberNo);
    Optional<Member> findByMemberNo(String memberNo);
    Optional<Member> findByPhone(String phone);
    Optional<Member> findByTenantIdAndPhone(String tenantId, String phone);
    Optional<Member> findByTenantIdAndMemberNo(String tenantId, String memberNo);
    List<Member> findByTenantId(String tenantId);
    long countByTenantId(String tenantId);

    @Query("SELECT m.tenantId, COUNT(m) FROM Member m WHERE m.tenantId IN :tenantIds GROUP BY m.tenantId")
    List<Object[]> countGroupByTenantIdIn(@Param("tenantIds") Collection<String> tenantIds);
    List<Member> findByTenantIdAndNameContainingOrTenantIdAndPhoneContaining(String t1, String name, String t2, String phone);
    List<Member> findByNameContainingOrPhoneContaining(String name, String phone);
    List<Member> findByPhoneEndingWith(String tailNumber);
    List<Member> findByTenantIdAndPhoneEndingWith(String tenantId, String tailNumber);
    List<Member> findByTenantIdAndWechatFollowStatusTrue(String tenantId);
    List<Member> findByTenantIdAndAlipayFollowStatusTrue(String tenantId);
}
