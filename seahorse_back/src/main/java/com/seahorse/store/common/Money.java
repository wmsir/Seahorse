package com.seahorse.store.common;

import com.fasterxml.jackson.annotation.JsonValue;
import jakarta.persistence.Embeddable;
import lombok.EqualsAndHashCode;

import java.io.Serializable;
import java.math.BigDecimal;
import java.math.RoundingMode;

@Embeddable
@EqualsAndHashCode
public class Money implements Serializable, Comparable<Money> {
    public static final Money ZERO = new Money(BigDecimal.ZERO);

    private BigDecimal amount;

    public Money() {
        this.amount = BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP);
    }

    public Money(BigDecimal amount) {
        this.amount = (amount == null ? BigDecimal.ZERO : amount).setScale(2, RoundingMode.HALF_UP);
    }

    public Money(double amount) {
        this(BigDecimal.valueOf(amount));
    }

    public Money(String amount) {
        this(new BigDecimal(amount));
    }

    public static Money of(BigDecimal amount) {
        return new Money(amount);
    }

    public static Money of(double amount) {
        return new Money(amount);
    }

    @JsonValue
    public BigDecimal getAmount() {
        return amount != null ? amount : BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP);
    }

    public Money add(Money other) {
        return new Money(this.getAmount().add(other.getAmount()));
    }

    public Money subtract(Money other) {
        return new Money(this.getAmount().subtract(other.getAmount()));
    }

    public Money multiply(BigDecimal factor) {
        return new Money(this.getAmount().multiply(factor));
    }

    public Money multiply(int count) {
        return new Money(this.getAmount().multiply(BigDecimal.valueOf(count)));
    }

    public Money multiply(double factor) {
        return new Money(this.getAmount().multiply(BigDecimal.valueOf(factor)));
    }

    public boolean isGreaterThan(Money other) {
        return this.compareTo(other) > 0;
    }

    public boolean isGreaterThanOrEqual(Money other) {
        return this.compareTo(other) >= 0;
    }

    public boolean isPositive() {
        return this.getAmount().compareTo(BigDecimal.ZERO) > 0;
    }

    public boolean isZero() {
        return this.getAmount().compareTo(BigDecimal.ZERO) == 0;
    }

    @Override
    public int compareTo(Money o) {
        if (o == null) return 1;
        return this.getAmount().compareTo(o.getAmount());
    }

    @Override
    public String toString() {
        return getAmount().toPlainString();
    }
}
