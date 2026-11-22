package com.algolab.algorithm;

import java.util.ArrayList;
import java.util.List;
import com.algolab.dto.SortStep;

/**
 * 임시 변수 key와 오른쪽 밀기(shift)를 사용하는 삽입 정렬입니다.
 *
 * pick    : 정렬할 값을 key로 들어 올리고 배열 자리를 빈자리로 표현
 * compare : 왼쪽 원소와 key를 비교
 * shift   : key보다 큰 원소를 한 칸 오른쪽으로 이동(빈자리가 왼쪽으로 이동)
 * insert  : 최종 빈자리에 key 삽입
 *
 * shift 순간의 배열에는 한 값이 임시로 중복되지만, holeIndex를 화면에서
 * 숨기면 선택한 값이 분리되고 나머지 원소가 실제로 이동하는 모습이 됩니다.
 */
public class InsertionSort implements SortingAlgorithm {
    @Override
    public List<SortStep> sort(int[] input) {
        int[] arr = input.clone();
        List<SortStep> steps = new ArrayList<>();
        steps.add(new SortStep(arr, -1, -1, "initial", 0, -1, -1, 0));

        for (int i = 1; i < arr.length; i++) {
            int key = arr[i];
            int hole = i;
            steps.add(new SortStep(arr, i, i, "pick", key, i, hole, i - 1));

            for (int j = i - 1; j >= 0; j--) {
                steps.add(new SortStep(arr, j, hole, "compare", key, i, hole, i - 1));
                if (arr[j] <= key) {
                    break;
                }
                arr[hole] = arr[j];
                int previousHole = hole;
                hole = j;
                steps.add(new SortStep(arr, j, previousHole, "shift", key, i, hole, i - 1));
            }

            arr[hole] = key;
            steps.add(new SortStep(arr, hole, i, "insert", key, i, -1, i));
        }
        steps.add(new SortStep(arr, -1, -1, "complete", 0, -1, -1, arr.length - 1));
        return steps;
    }
}
