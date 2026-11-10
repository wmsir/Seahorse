package com.seahorse.store.infrastructure.repository;

import com.seahorse.store.domain.member.model.TimeCardBucket;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TimeCardBucketRepository extends JpaRepository<TimeCardBucket, Long> {
    List<TimeCardBucket> findByMemberId(Long memberId);
    List<TimeCardBucket> findByMemberIdAndStatus(Long memberId, String status);
}
