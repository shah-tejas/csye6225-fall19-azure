package com.csye6225.random.model;

import org.springframework.data.annotation.ReadOnlyProperty;

import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import java.util.UUID;

@Entity(name = "random_number")
public class RandomNumber {
    @ReadOnlyProperty
    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;
    private int randomNumber;

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public int getRandomNumber() {
        return randomNumber;
    }

    public void setRandomNumber(int randomNumber) {
        this.randomNumber = randomNumber;
    }
}
