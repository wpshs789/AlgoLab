package com.algolab.dto;

public class SortStep {
    private final int[] array;
    private final int index1;
    private final int index2;
    private final String action;

    public SortStep(int[] array, int index1, int index2, String action) {
        this.array = array.clone(); // 각 단계의 배열을 별도로 보존
        this.index1 = index1;
        this.index2 = index2;
        this.action = action;
    }

    public int[] getArray() {
        return array.clone();
    }

    public int getIndex1() {
        return index1;
    }

    public int getIndex2() {
        return index2;
    }

    public String getAction() {
        return action;
    }
}
