package com.algolab.benchmark;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/** 같은 조건/입력으로 실행한 다섯 정렬의 성능 비교 결과. */
public final class BenchmarkReport {
    private final int arraySize;
    private final String pattern;
    private final int repetitions;
    private final List<BenchmarkResult> results;

    public BenchmarkReport(int arraySize, String pattern, int repetitions, List<BenchmarkResult> results) {
        if (arraySize < 1 || arraySize > 5000 || repetitions < 1 || repetitions > 10
                || !isSupportedPattern(pattern) || results == null || results.size() != 5) {
            throw new IllegalArgumentException("성능 비교 조건이 올바르지 않습니다.");
        }
        this.arraySize = arraySize;
        this.pattern = pattern;
        this.repetitions = repetitions;
        this.results = Collections.unmodifiableList(new ArrayList<>(results));
    }

    public int getArraySize() { return arraySize; }
    public String getPattern() { return pattern; }
    public int getRepetitions() { return repetitions; }
    public List<BenchmarkResult> getResults() { return results; }

    public String getPatternLabel() {
        switch (pattern) {
            case "random": return "무작위";
            case "ascending": return "오름차순 정렬됨";
            case "descending": return "내림차순(역순)";
            case "nearly": return "거의 정렬됨";
            default: return pattern;
        }
    }

    public static boolean isSupportedPattern(String pattern) {
        return "random".equals(pattern) || "ascending".equals(pattern)
                || "descending".equals(pattern) || "nearly".equals(pattern);
    }
}
