package com.algolab.dto;

import java.io.Serializable;
import java.sql.Timestamp;

/** 게시판에 저장할 단일 실험 기록. JSP에서 사용하는 JavaBeans. */
public class Experiment implements Serializable {
    private static final long serialVersionUID = 1L;

    private long id;
    private String experimentType = "VISUALIZATION";
    private String title = "";
    private String algorithm = "";
    private String inputArray = "";
    private int arraySize;
    private long comparisons;
    private long swaps;
    private String memo = "";
    private Timestamp createdAt;

    public Experiment() { }

    public long getId() { return id; }
    public void setId(long id) { this.id = id; }

    public String getExperimentType() { return experimentType; }
    public void setExperimentType(String experimentType) { this.experimentType = experimentType; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getAlgorithm() { return algorithm; }
    public void setAlgorithm(String algorithm) { this.algorithm = algorithm; }

    public String getInputArray() { return inputArray; }
    public void setInputArray(String inputArray) { this.inputArray = inputArray; }

    public int getArraySize() { return arraySize; }
    public void setArraySize(int arraySize) { this.arraySize = arraySize; }

    public long getComparisons() { return comparisons; }
    public void setComparisons(long comparisons) { this.comparisons = comparisons; }

    public long getSwaps() { return swaps; }
    public void setSwaps(long swaps) { this.swaps = swaps; }

    public String getMemo() { return memo; }
    public void setMemo(String memo) { this.memo = memo; }

    public Timestamp getCreatedAt() { return createdAt; }
    public void setCreatedAt(Timestamp createdAt) { this.createdAt = createdAt; }

    public String getAlgorithmLabel() {
        if ("bubble".equals(algorithm)) return "Bubble Sort";
        if ("selection".equals(algorithm)) return "Selection Sort";
        if ("insertion".equals(algorithm)) return "Insertion Sort";
        if ("merge".equals(algorithm)) return "Merge Sort";
        return algorithm;
    }
}
