package com.algolab.benchmark;

/** 하나의 정렬 알고리즘에 대해 반복 측정한 평균값(시각화 객체 생성 제외). */
public final class BenchmarkResult {
    private final String algorithm;
    private final double averageNanoseconds;
    private final double averageComparisons;
    private final double averageOperations;

    public BenchmarkResult(String algorithm, double averageNanoseconds,
                           double averageComparisons, double averageOperations) {
        if (!isSupported(algorithm) || !Double.isFinite(averageNanoseconds)
                || !Double.isFinite(averageComparisons) || !Double.isFinite(averageOperations)
                || averageNanoseconds < 0 || averageComparisons < 0 || averageOperations < 0) {
            throw new IllegalArgumentException("측정 결과가 올바르지 않습니다.");
        }
        this.algorithm = algorithm;
        this.averageNanoseconds = averageNanoseconds;
        this.averageComparisons = averageComparisons;
        this.averageOperations = averageOperations;
    }

    public String getAlgorithm() { return algorithm; }
    public double getAverageNanoseconds() { return averageNanoseconds; }
    public double getAverageMilliseconds() { return averageNanoseconds / 1_000_000.0; }
    public double getAverageComparisons() { return averageComparisons; }
    public double getAverageOperations() { return averageOperations; }

    public String getLabel() {
        switch (algorithm) {
            case "bubble": return "Bubble Sort";
            case "selection": return "Selection Sort";
            case "insertion": return "Insertion Sort";
            case "merge": return "Merge Sort";
            case "quick": return "Quick Sort";
            default: return algorithm;
        }
    }

    public String getOperationLabel() {
        if ("insertion".equals(algorithm)) return "밀기(Shift)";
        if ("merge".equals(algorithm)) return "병합 배치";
        return "교환(Swap)";
    }

    public String getAverageComplexity() {
        return ("merge".equals(algorithm) || "quick".equals(algorithm)) ? "O(n log n)" : "O(n²)";
    }

    public String getWorstComplexity() {
        return "merge".equals(algorithm) ? "O(n log n)" : "O(n²)";
    }

    public static boolean isSupported(String algorithm) {
        return "bubble".equals(algorithm) || "selection".equals(algorithm)
                || "insertion".equals(algorithm) || "merge".equals(algorithm)
                || "quick".equals(algorithm);
    }
}
