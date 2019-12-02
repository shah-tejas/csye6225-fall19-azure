package com.csye6225.random.controller;

import com.csye6225.random.model.RandomNumber;
import com.csye6225.random.respository.RandomNumberRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Random;

@RestController
public class RandomController {

    @Autowired
    RandomNumberRepository randomNumberRepository;

    @GetMapping("/generate")
    public ResponseEntity<Integer> generateRandom() {
        Random random = new Random();
        // generate a random int between 0 and 1000
        int rand_int = random.nextInt(1000);
        RandomNumber number = new RandomNumber();
        number.setRandomNumber(rand_int);
        randomNumberRepository.save(number);

        return new ResponseEntity<Integer>(rand_int, HttpStatus.OK);
    }
}
