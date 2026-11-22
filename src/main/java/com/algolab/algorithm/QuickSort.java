package com.algolab.algorithm;

import java.util.ArrayList;
import java.util.List;
import com.algolab.dto.SortStep;

/**
 * 퀵 정렬 (Lomuto 분할): 항상 현재 구간의 맨 오른쪽 값을 피벗으로 선택합니다.
 *
 * quickStart : 현재 구간과 피벗 표시
 * compare    : 스캔 중인 원소와 피벗 비교
 * quickKeep  : 현재 원소가 피벗 이하이고 제자리에 있어 경계만 전진
 * quickSkip  : 현재 원소가 피벗보다 커서 오른쪽 그룹에 남음
 * swap       : 피벗 이하 원소를 왼쪽 그룹으로 교환 (실제 위치가 다를 때만)
 * swapPivot  : 피벗을 최종 위치와 교환 (실제 위치가 다를 때만)
 * quickPlaced: 피벗의 최종 위치 확정
 * quickSingle: 원소 하나의 구간 확정
 *
 * rangeMid는 '피벗 이하 그룹의 마지막 인덱스'(-1일 수 있음)로 사용합니다.
 * 화면은 Java가 기록한 배열/구간만 렌더링합니다.
 */
public final class QuickSort implements SortingAlgorithm {
    @Override
    public List<SortStep> sort(int[] input) {
        if (input == null || input.length == 0) {
            throw new IllegalArgumentException("정렬할 배열이 없습니다.");
        }
        int[] arr = input.clone();
        List<SortStep> steps = new ArrayList<>();
        steps.add(new SortStep(arr, -1, -1, "initial"));
        quickSort(arr, 0, arr.length - 1, 0, steps);
        steps.add(new SortStep(arr, -1, -1, "complete"));
        return steps;
    }

    private void quickSort(int[] arr, int left, int right, int depth, List<SortStep> steps) {
        if (left > right) return;
        if (left == right) {
            steps.add(quickStep(arr, left, -1, "quickSingle", left, left, right, depth));
            return;
        }

        int pivot = arr[right];
        int boundary = left - 1;
        steps.add(quickStep(arr, right, -1, "quickStart", left, boundary, right, depth));

        for (int scan = left; scan < right; scan++) {
            steps.add(quickStep(arr, scan, right, "compare", left, boundary, right, depth));
            if (arr[scan] <= pivot) {
                boundary++;
                if (boundary == scan) {
                    steps.add(quickStep(arr, scan, right, "quickKeep", left, boundary, right, depth));
                } else {
                    swap(arr, boundary, scan);
                    steps.add(quickStep(arr, boundary, scan, "swap", left, boundary, right, depth));
                }
            } else {
                steps.add(quickStep(arr, scan, right, "quickSkip", left, boundary, right, depth));
            }
        }

        int pivotPosition = boundary + 1;
        if (pivotPosition != right) {
            swap(arr, pivotPosition, right);
            steps.add(quickStep(arr, pivotPosition, right, "swapPivot", left, boundary, right, depth));
        }
        steps.add(quickStep(arr, pivotPosition, right, "quickPlaced", left, pivotPosition, right, depth));

        quickSort(arr, left, pivotPosition - 1, depth + 1, steps);
        quickSort(arr, pivotPosition + 1, right, depth + 1, steps);
    }

    private void swap(int[] arr, int a, int b) {
        int temp = arr[a];
        arr[a] = arr[b];
        arr[b] = temp;
    }

    private SortStep quickStep(int[] arr, int index1, int index2, String action,
                               int left, int boundary, int right, int depth) {
        // 기존 SortStep의 범위 메타데이터를 재사용하므로 DB와 DTO 변경이 필요 없습니다.
        return new SortStep(arr, index1, index2, action,
                0, -1, -1, -1, left, boundary, right, depth, new int[0]);
    }
}
