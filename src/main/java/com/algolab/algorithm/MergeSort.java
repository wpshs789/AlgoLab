package com.algolab.algorithm;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import com.algolab.dto.SortStep;

/**
 * 병합 정렬을 '분할 -> 부분 배열 정렬 -> 병합' 순서로 기록합니다.
 *
 * compare   : 두 정렬된 부분 배열의 맨 앞 후보를 비교한 횟수
 * mergeTake : 임시 병합 배열에 원소를 한 번 배치한 횟수
 *
 * 메모리 복사를 포함한 모든 쓰기 명령 수가 아닌, 학습용 '병합 배치' 횟수를 셉니다.
 * 비교가 끝난 나머지 원소도 병합 배열에 배치되므로 mergeTake로 기록합니다.
 */
public final class MergeSort implements SortingAlgorithm {
    @Override
    public List<SortStep> sort(int[] input) {
        if (input == null || input.length == 0) {
            throw new IllegalArgumentException("정렬할 배열이 없습니다.");
        }
        int[] arr = input.clone();
        List<SortStep> steps = new ArrayList<>();
        steps.add(new SortStep(arr, -1, -1, "initial"));
        mergeSort(arr, 0, arr.length - 1, 0, steps);
        steps.add(new SortStep(arr, -1, -1, "complete"));
        return steps;
    }

    private void mergeSort(int[] arr, int left, int right, int depth, List<SortStep> steps) {
        if (left == right) {
            steps.add(mergeStep(arr, -1, -1, "mergeLeaf", left, -1, right, depth, new int[0]));
            return;
        }
        int mid = left + (right - left) / 2;
        steps.add(mergeStep(arr, -1, -1, "mergeSplit", left, mid, right, depth, new int[0]));
        mergeSort(arr, left, mid, depth + 1, steps);
        mergeSort(arr, mid + 1, right, depth + 1, steps);

        int i = left;
        int j = mid + 1;
        int length = right - left + 1;
        int[] merged = new int[length];
        int written = 0;
        while (i <= mid && j <= right) {
            steps.add(mergeStep(arr, i, j, "compare", left, mid, right, depth,
                    Arrays.copyOf(merged, written)));
            // 같을 때 왼쪽 값부터 선택하므로 안정 정렬을 유지합니다.
            if (arr[i] <= arr[j]) {
                merged[written++] = arr[i];
                steps.add(mergeStep(arr, i, left + written - 1, "mergeTake", left, mid, right, depth,
                        Arrays.copyOf(merged, written)));
                i++;
            } else {
                merged[written++] = arr[j];
                steps.add(mergeStep(arr, j, left + written - 1, "mergeTake", left, mid, right, depth,
                        Arrays.copyOf(merged, written)));
                j++;
            }
        }
        while (i <= mid) {
            merged[written++] = arr[i];
            steps.add(mergeStep(arr, i, left + written - 1, "mergeTake", left, mid, right, depth,
                    Arrays.copyOf(merged, written)));
            i++;
        }
        while (j <= right) {
            merged[written++] = arr[j];
            steps.add(mergeStep(arr, j, left + written - 1, "mergeTake", left, mid, right, depth,
                    Arrays.copyOf(merged, written)));
            j++;
        }
        System.arraycopy(merged, 0, arr, left, length);
        steps.add(mergeStep(arr, -1, -1, "mergeDone", left, mid, right, depth, merged));
    }

    private SortStep mergeStep(int[] arr, int index1, int index2, String action,
                               int left, int mid, int right, int depth, int[] output) {
        return new SortStep(arr, index1, index2, action,
                0, -1, -1, -1, left, mid, right, depth, output);
    }
}
