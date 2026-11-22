package com.algolab.algorithm;

import java.util.ArrayList;
import java.util.List;
import com.algolab.dto.SortStep;

/** 선택 정렬: 남은 구간의 최솟값을 선택하여 앞쪽에 배치합니다. */
public class SelectionSort implements SortingAlgorithm {
    @Override
    public List<SortStep> sort(int[] input) {
        int[] arr = input.clone();
        List<SortStep> steps = new ArrayList<>();
        steps.add(new SortStep(arr, -1, -1, "initial"));

        for (int i = 0; i < arr.length - 1; i++) {
            int minIndex = i;
            steps.add(new SortStep(arr, i, minIndex, "select"));
            for (int j = i + 1; j < arr.length; j++) {
                steps.add(new SortStep(arr, minIndex, j, "compare"));
                if (arr[j] < arr[minIndex]) {
                    minIndex = j;
                    steps.add(new SortStep(arr, i, minIndex, "select"));
                }
            }
            if (i != minIndex) {
                int tmp = arr[i];
                arr[i] = arr[minIndex];
                arr[minIndex] = tmp;
                steps.add(new SortStep(arr, i, minIndex, "swap"));
            }
            steps.add(new SortStep(arr, i, -1, "fixed"));
        }
        steps.add(new SortStep(arr, -1, -1, "complete"));
        return steps;
    }
}
