package com.seahorse.store.infrastructure.repository;

import com.seahorse.store.domain.notice.model.StoreNotice;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface StoreNoticeRepository extends JpaRepository<StoreNotice, Long> {

    /**
     * 查询指定租户下指定门店及本租户全店通用的有效规范与公告 (状态为 PUBLISHED，按发布/更新时间倒序)
     */
    @Query("SELECT n FROM StoreNotice n WHERE n.tenantId = :tenantId AND (n.storeId = :storeId OR n.storeId = 'ALL') AND n.status = 'PUBLISHED' ORDER BY n.isUrgent DESC, n.createdAt DESC")
    List<StoreNotice> findActiveNoticesByTenantAndStore(@Param("tenantId") String tenantId, @Param("storeId") String storeId);

    /**
     * 仅按精确门店ID查询有效公告 (不含跨租户 ALL)
     */
    @Query("SELECT n FROM StoreNotice n WHERE n.storeId = :storeId AND n.status = 'PUBLISHED' ORDER BY n.isUrgent DESC, n.createdAt DESC")
    List<StoreNotice> findActiveNoticesByStoreId(@Param("storeId") String storeId);

    /**
     * 查询商户下所有门店的公告列表
     */
    List<StoreNotice> findByTenantIdAndStatusOrderByCreatedAtDesc(String tenantId, String status);

    /**
     * 查询指定租户下指定门店当前最新的一条未撤销且需要播放提示音的特别重要通知
     */
    @Query("SELECT n FROM StoreNotice n WHERE n.tenantId = :tenantId AND (n.storeId = :storeId OR n.storeId = 'ALL') AND n.status = 'PUBLISHED' AND n.isUrgent = true ORDER BY n.createdAt DESC")
    List<StoreNotice> findUrgentNoticesByTenantAndStore(@Param("tenantId") String tenantId, @Param("storeId") String storeId);

    /**
     * 仅按精确门店ID查询紧急通知 (不含跨租户 ALL)
     */
    @Query("SELECT n FROM StoreNotice n WHERE n.storeId = :storeId AND n.status = 'PUBLISHED' AND n.isUrgent = true ORDER BY n.createdAt DESC")
    List<StoreNotice> findUrgentNoticesByStoreId(@Param("storeId") String storeId);
}
