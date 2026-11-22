package com.algolab.dto;

/**
 * 시각화용 정렬 단계의 불변 스냅샷입니다.
 *
 * 삽입 정렬에서는 key를 별도로 보관하며, holeIndex는 key를 꺼낸 빈자리입니다.
 * 배열 스냅샷의 holeIndex 위치에는 이전 값이 남아 있을 수 있으므로,
 * 화면에서는 반드시 빈자리로 표시해야 합니다.
 */
public class SortStep {
    private final int[] array;
    private final int index1;
    private final int index2;
    private final String action;
    private final int keyValue;
    private final int keyOrigin;
    private final int holeIndex;
    private final int sortedEnd;

    // 병합 정렬용 구간(양 끝 포함), 깊이, 임시 병합 결과.
    private final int rangeLeft;
    private final int rangeMid;
    private final int rangeRight;
    private final int depth;
    private final int[] mergeOutput;

    /** 버블/선택 정렬 등 기존 호출과 호환됩니다. */
    public SortStep(int[] array, int index1, int index2, String action) {
        this(array, index1, index2, action, 0, -1, -1, -1);
    }

    /** 삽입 정렬의 선택한 key, 빈자리, 정렬 완료 구간을 기록합니다. */
    public SortStep(int[] array, int index1, int index2, String action,
                    int keyValue, int keyOrigin, int holeIndex, int sortedEnd) {
        this(array, index1, index2, action, keyValue, keyOrigin, holeIndex, sortedEnd,
                -1, -1, -1, -1, new int[0]);
    }

    /** 병합 정렬의 분할 구간과 부분적으로 채워진 병합 결과를 기록합니다. */
    public SortStep(int[] array, int index1, int index2, String action,
                    int keyValue, int keyOrigin, int holeIndex, int sortedEnd,
                    int rangeLeft, int rangeMid, int rangeRight, int depth, int[] mergeOutput) {
        this.array = array.clone();
        this.index1 = index1;
        this.index2 = index2;
        this.action = action;
        this.keyValue = keyValue;
        this.keyOrigin = keyOrigin;
        this.holeIndex = holeIndex;
        this.sortedEnd = sortedEnd;
        this.rangeLeft = rangeLeft;
        this.rangeMid = rangeMid;
        this.rangeRight = rangeRight;
        this.depth = depth;
        this.mergeOutput = mergeOutput.clone();
    }

    public int[] getArray() { return array.clone(); }
    public int getIndex1() { return index1; }
    public int getIndex2() { return index2; }
    public String getAction() { return action; }
    public int getKeyValue() { return keyValue; }
    public int getKeyOrigin() { return keyOrigin; }
    public int getHoleIndex() { return holeIndex; }
    public int getSortedEnd() { return sortedEnd; }
    public int getRangeLeft() { return rangeLeft; }
    public int getRangeMid() { return rangeMid; }
    public int getRangeRight() { return rangeRight; }
    public int getDepth() { return depth; }
    public int[] getMergeOutput() { return mergeOutput.clone(); }
}
