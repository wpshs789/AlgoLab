package com.algolab.service;

import java.util.List;
import com.algolab.algorithm.BubbleSort;
import com.algolab.algorithm.SortingAlgorithm;
import com.algolab.dto.SortStep;

public class SortingService {
    public List<SortStep> sort(String algorithm, int[] array) {
        SortingAlgorithm sorter;
        if ("bubble".equals(algorithm)) {
            sorter = new BubbleSort();
        } else {
            throw new IllegalArgumentException("지원하지 않는 알고리즘입니다.");
        }
        return sorter.sort(array);
    }
}
