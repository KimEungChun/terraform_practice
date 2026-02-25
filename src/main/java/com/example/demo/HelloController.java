package com.example.demo;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloController {

  @GetMapping("/")
  public String root() {
    return "OK";
  }

  @GetMapping("/hello")
  public String hello() {
    return "hello from simple-java-app";
  }
}