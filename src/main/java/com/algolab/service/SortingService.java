package com.algolab.service;

import java.util.List;
import com.algolab.algorithm.BubbleSort;
import com.algolab.algorithm.SelectionSort;
import com.algolab.algorithm.InsertionSort;
import com.algolab.algorithm.MergeSort;
import com.algolab.algorithm.QuickSort;
import com.algolab.algorithm.SortingAlgorithm;
import com.algolab.dto.SortStep;

/** 시각화용 정렬 알고리즘을 선택하는 서비스입니다. */
public class SortingService {
    public List<SortStep> sort(String algorithm, int[] array) {
        if (array == null || array.length < 1 || array.length > 30) {
            throw new IllegalArgumentException("숫자는 1~30개까지 입력할 수 있습니다.");
        }
        SortingAlgorithm sorter;
        if ("bubble".equals(algorithm)) {
            sorter = new BubbleSort();
        } else if ("selection".equals(algorithm)) {
            sorter = new SelectionSort();
        } else if ("insertion".equals(algorithm)) {
            sorter = new InsertionSort();
        } else if ("merge".equals(algorithm)) {
            sorter = new MergeSort();
        } else if ("quick".equals(algorithm)) {
            sorter = new QuickSort();
        } else {
            throw new IllegalArgumentException("지원하지 않는 알고리즘입니다.");
        }
        return sorter.sort(array);
    }

    public static boolean isSupported(String algorithm) {
        return "bubble".equals(algorithm)
            || "selection".equals(algorithm)
            || "insertion".equals(algorithm)
            || "merge".equals(algorithm)
            || "quick".equals(algorithm);
    }
}
