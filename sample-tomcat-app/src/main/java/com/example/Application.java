package com.example;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.boot.web.servlet.support.SpringBootServletInitializer;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@SpringBootApplication
@RestController
public class Application extends SpringBootServletInitializer {

    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }

    @Override
    protected SpringApplicationBuilder configure(SpringApplicationBuilder builder) {
        return builder.sources(Application.class);
    }

    @GetMapping("/")
    public String home() {
        return "Welcome to Sample Tomcat App!";
    }

    @GetMapping("/health")
    public String health() {
        return "Application is running on Java 17";
    }

    @GetMapping("/api/message")
    public Message getMessage() {
        return new Message("Hello from Sample App", "Java 17 + Spring Boot 3.2.0 + Tomcat");
    }

    public static class Message {
        public String title;
        public String description;

        public Message(String title, String description) {
            this.title = title;
            this.description = description;
        }

        public String getTitle() {
            return title;
        }

        public String getDescription() {
            return description;
        }
    }
}
