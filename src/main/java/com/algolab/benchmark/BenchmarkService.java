package com.algolab.benchmark;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.SplittableRandom;

/**
 * 정렬 시각화(SortStep)를 전혀 생성하지 않는 독립 벤치마크.
 * 배열 복사와 정답 검증은 측정 구간 밖에서 실행합니다.
 * 동일한 반복 회차에서는 다섯 알고리즘에 완전히 같은 배열을 전달합니다.
 */
public final class BenchmarkService {
    private static final String[] ALGORITHMS = {"bubble", "selection", "insertion", "merge", "quick"};
    private static final long BASE_SEED = 202611230417L;

    private BenchmarkService() { }

    public static BenchmarkReport measure(int n, String pattern, int repeats) {
        if (n < 10 || n > 5000 || !BenchmarkReport.isSupportedPattern(pattern)
                || repeats < 1 || repeats > 10) {
            throw new IllegalArgumentException("배열 크기는 10~5,000개, 반복 횟수는 1~10회로 설정해 주세요.");
        }

        // 가벼운 JVM 워밍업. 전체 결과에 포함하지 않으며 실제 측정과도 분리합니다.
        int warmupSize = Math.min(n, 200);
        for (int round = 0; round < 3; round++) {
            int[] warm = createInput(warmupSize, pattern, BASE_SEED - 100 - round);
            for (String algorithm : ALGORITHMS) {
                sort(algorithm, warm.clone(), new Counters());
            }
        }

        long[] nanoTotals = new long[ALGORITHMS.length];
        long[] comparisonTotals = new long[ALGORITHMS.length];
        long[] operationTotals = new long[ALGORITHMS.length];

        for (int round = 0; round < repeats; round++) {
            int[] original = createInput(n, pattern, BASE_SEED + round);
            int[] expected = original.clone();
            Arrays.sort(expected); // 검증은 측정 시간에 포함하지 않음

            // 한 알고리즘이 매번 먼저 실행되지 않게 시작 순서를 교대합니다.
            for (int step = 0; step < ALGORITHMS.length; step++) {
                int index = (round + step) % ALGORITHMS.length;
                int[] data = original.clone(); // 정렬마다 동일한 입력을 복사
                Counters count = new Counters();
                long start = System.nanoTime();
                sort(ALGORITHMS[index], data, count);
                long elapsed = System.nanoTime() - start;
                if (!Arrays.equals(data, expected)) {
                    throw new IllegalStateException(ALGORITHMS[index] + " 정렬 검증에 실패했습니다.");
                }
                nanoTotals[index] += elapsed;
                comparisonTotals[index] += count.comparisons;
                operationTotals[index] += count.operations;
            }
        }

        List<BenchmarkResult> rows = new ArrayList<>();
        for (int i = 0; i < ALGORITHMS.length; i++) {
            rows.add(new BenchmarkResult(ALGORITHMS[i],
                (double) nanoTotals[i] / repeats,
                (double) comparisonTotals[i] / repeats,
                (double) operationTotals[i] / repeats));
        }
        return new BenchmarkReport(n, pattern, repeats, rows);
    }

    static int[] createInput(int n, String pattern, long seed) {
        int[] array = new int[n];
        SplittableRandom random = new SplittableRandom(seed);
        if ("random".equals(pattern)) {
            for (int i = 0; i < n; i++) array[i] = random.nextInt(-10_000, 10_001);
        } else {
            for (int i = 0; i < n; i++) array[i] = i - n / 2;
            if ("descending".equals(pattern)) {
                for (int i = 0; i < n / 2; i++) swap(array, i, n - 1 - i);
            } else if ("nearly".equals(pattern)) {
                // 오름차순 배열에서 약 5% 위치 쌍을 교환한 입력
                for (int i = 0; i < Math.max(1, n / 20); i++) {
                    int p = random.nextInt(n);
                    int q = random.nextInt(n);
                    swap(array, p, q);
                }
            }
        }
        return array;
    }

    private static void sort(String algorithm, int[] a, Counters m) {
        switch (algorithm) {
            case "bubble": bubble(a, m); return;
            case "selection": selection(a, m); return;
            case "insertion": insertion(a, m); return;
            case "merge": mergeSort(a, 0, a.length - 1, new int[a.length], m); return;
            case "quick": quick(a, m); return;
            default: throw new IllegalArgumentException("지원하지 않는 알고리즘입니다.");
        }
    }

    // 시각화 BubbleSort와 동일하게 조기 종료 최적화를 사용하지 않습니다.
    private static void bubble(int[] a, Counters m) {
        for (int i = 0; i < a.length - 1; i++) {
            for (int j = 0; j < a.length - 1 - i; j++) {
                m.comparisons++;
                if (a[j] > a[j + 1]) { swap(a, j, j + 1); m.operations++; }
            }
        }
    }

    private static void selection(int[] a, Counters m) {
        for (int i = 0; i < a.length - 1; i++) {
            int min = i;
            for (int j = i + 1; j < a.length; j++) {
                m.comparisons++;
                if (a[j] < a[min]) min = j;
            }
            if (min != i) { swap(a, i, min); m.operations++; }
        }
    }

    private static void insertion(int[] a, Counters m) {
        for (int i = 1; i < a.length; i++) {
            int key = a[i];
            int j = i - 1;
            while (j >= 0) {
                m.comparisons++;
                if (a[j] <= key) break;
                a[j + 1] = a[j];
                m.operations++; // key의 마지막 배치는 shift로 세지 않음
                j--;
            }
            a[j + 1] = key;
        }
    }

    private static void mergeSort(int[] a, int lo, int hi, int[] temp, Counters m) {
        if (lo >= hi) return;
        int mid = lo + (hi - lo) / 2;
        mergeSort(a, lo, mid, temp, m);
        mergeSort(a, mid + 1, hi, temp, m);
        int i = lo, j = mid + 1, k = lo;
        while (i <= mid && j <= hi) {
            m.comparisons++;
            temp[k++] = a[i] <= a[j] ? a[i++] : a[j++];
            m.operations++;
        }
        while (i <= mid) { temp[k++] = a[i++]; m.operations++; }
        while (j <= hi) { temp[k++] = a[j++]; m.operations++; }
        System.arraycopy(temp, lo, a, lo, hi - lo + 1);
    }

    /** Lomuto, 끝 원소 피벗. 반복문 + 작은 구간 우선으로 정렬된 큰 배열의 재귀 스택 폭주를 방지합니다. */
    private static void quick(int[] a, Counters m) {
        if (a.length < 2) return;
        int[] stack = new int[a.length * 2];
        int top = 0;
        stack[top++] = 0;
        stack[top++] = a.length - 1;
        while (top != 0) {
            int hi = stack[--top];
            int lo = stack[--top];
            while (lo < hi) {
                int p = partition(a, lo, hi, m);
                int leftLength = p - lo;
                int rightLength = hi - p;
                if (leftLength < rightLength) {
                    if (p + 1 < hi) { stack[top++] = p + 1; stack[top++] = hi; }
                    hi = p - 1;
                } else {
                    if (lo < p - 1) { stack[top++] = lo; stack[top++] = p - 1; }
                    lo = p + 1;
                }
            }
        }
    }

    private static int partition(int[] a, int lo, int hi, Counters m) {
        int pivot = a[hi];
        int bound = lo - 1;
        for (int j = lo; j < hi; j++) {
            m.comparisons++;
            if (a[j] <= pivot) {
                bound++;
                if (bound != j) { swap(a, bound, j); m.operations++; }
            }
        }
        int pivotIndex = bound + 1;
        if (pivotIndex != hi) { swap(a, pivotIndex, hi); m.operations++; }
        return pivotIndex;
    }

    private static void swap(int[] a, int i, int j) {
        int t = a[i]; a[i] = a[j]; a[j] = t;
    }

    private static final class Counters {
        long comparisons;
        long operations;
    }
}
