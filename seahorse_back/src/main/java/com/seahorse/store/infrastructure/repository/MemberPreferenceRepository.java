package com.seahorse.store.infrastructure.repository;

import com.seahorse.store.domain.member.model.MemberPreference;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MemberPreferenceRepository extends JpaRepository<MemberPreference, Long> {
    List<MemberPreference> findByMemberId(Long memberId);
    List<MemberPreference> findByMemberIdAndCategory(Long memberId, String category);
}
