package com.algolab.benchmark;

import java.sql.Timestamp;

/** DB에 저장된 성능 비교 실험의 메타데이터와 결과. */
public final class BenchmarkRecord {
    private final long id;
    private final String title;
    private final Timestamp createdAt;
    private final BenchmarkReport report;

    public BenchmarkRecord(long id, String title, Timestamp createdAt, BenchmarkReport report) {
        this.id = id;
        this.title = title;
        this.createdAt = createdAt;
        this.report = report;
    }

    public long getId() { return id; }
    public String getTitle() { return title; }
    public Timestamp getCreatedAt() { return createdAt; }
    public BenchmarkReport getReport() { return report; }
}
