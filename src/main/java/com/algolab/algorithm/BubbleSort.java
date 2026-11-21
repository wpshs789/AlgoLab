package com.algolab.algorithm;

import java.util.ArrayList;
import java.util.List;
import com.algolab.dto.SortStep;

public class BubbleSort implements SortingAlgorithm {
    @Override
    public List<SortStep> sort(int[] input) {
        int[] arr = input.clone();
        List<SortStep> steps = new ArrayList<>();
        steps.add(new SortStep(arr, -1, -1, "initial"));

        for (int i = 0; i < arr.length - 1; i++) {
            for (int j = 0; j < arr.length - 1 - i; j++) {
                steps.add(new SortStep(arr, j, j + 1, "compare"));
                if (arr[j] > arr[j + 1]) {
                    int tmp = arr[j];
                    arr[j] = arr[j + 1];
                    arr[j + 1] = tmp;
                    steps.add(new SortStep(arr, j, j + 1, "swap"));
                }
            }
        }
        steps.add(new SortStep(arr, -1, -1, "complete"));
        return steps;
    }
}
