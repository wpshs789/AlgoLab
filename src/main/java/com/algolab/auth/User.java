package com.algolab.auth;
import java.io.Serializable;

/** 세션에는 비밀번호 없이 로그인한 회원의 식별 정보만 저장합니다. */
public record User(long id, String username, String displayName) implements Serializable { }
