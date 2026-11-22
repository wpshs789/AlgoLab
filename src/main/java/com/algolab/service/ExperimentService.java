package com.algolab.service;

import java.util.List;
import java.util.StringJoiner;
import com.algolab.dto.Experiment;
import com.algolab.dto.SortStep;

/** 시각화에서 생성한 단계 기록을 게시판 저장용 집계값으로 바꾼다. */
public final class ExperimentService {
    private ExperimentService() { }

    public static Experiment fromVisualization(String algorithm, int[] input, List<SortStep> steps) {
        if (!SortingService.isSupported(algorithm) || input == null || input.length < 1 || input.length > 30
                || steps == null || steps.isEmpty()) {
            throw new IllegalArgumentException("저장할 수 없는 시각화 결과입니다.");
        }

        long comparisons = 0;
        long swaps = 0;
        for (SortStep step : steps) {
            if ("compare".equals(step.getAction())) comparisons++;
            // 삽입 정렬의 shift 1회는 오른쪽으로 원소를 1칸 옮기는 동작입니다.
            // 기존 DB의 swaps 컬럼에는 알고리즘별 교환/이동/병합 배치 횟수를 저장합니다.
            if ("swap".equals(step.getAction()) || "shift".equals(step.getAction())
                    || "mergeTake".equals(step.getAction())
                    || "swapPivot".equals(step.getAction())) swaps++;
        }

        StringJoiner numbers = new StringJoiner(",");
        for (int value : input) numbers.add(Integer.toString(value));

        Experiment experiment = new Experiment();
        experiment.setExperimentType("VISUALIZATION");
        experiment.setAlgorithm(algorithm);
        experiment.setInputArray(numbers.toString());
        experiment.setArraySize(input.length);
        experiment.setComparisons(comparisons);
        experiment.setSwaps(swaps);
        return experiment;
    }
}
