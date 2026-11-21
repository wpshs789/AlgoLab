package com.algolab.service;

import java.util.List;
import java.util.StringJoiner;
import com.algolab.dto.Experiment;
import com.algolab.dto.SortStep;

/** 시각화에서 생성한 단계 기록을 게시판 저장용 집계값으로 바꾼다. */
public final class ExperimentService {
    private ExperimentService() { }

    public static Experiment fromVisualization(String algorithm, int[] input, List<SortStep> steps) {
        if (!"bubble".equals(algorithm) || input == null || input.length < 1 || input.length > 30
                || steps == null || steps.isEmpty()) {
            throw new IllegalArgumentException("저장할 수 없는 시각화 결과입니다.");
        }

        long comparisons = 0;
        long swaps = 0;
        for (SortStep step : steps) {
            if ("compare".equals(step.getAction())) comparisons++;
            if ("swap".equals(step.getAction())) swaps++;
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
