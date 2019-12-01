package com.csye6225.random.respository;

import com.csye6225.random.model.RandomNumber;
import org.springframework.data.repository.CrudRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface RandomNumberRepository extends CrudRepository<RandomNumber, UUID> {
}
