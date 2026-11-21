package com.algolab.algorithm;

import java.util.List;
import com.algolab.dto.SortStep;

public interface SortingAlgorithm {
    List<SortStep> sort(int[] array);
}
