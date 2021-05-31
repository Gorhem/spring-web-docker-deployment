package com.gorhem.springdocker.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RequestMapping("/")
@RestController
public class HomeRestController {

    @GetMapping
    public String get(){
        return "Your application has been successfully deployed!";
    }
}
