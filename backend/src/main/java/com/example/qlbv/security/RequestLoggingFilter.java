package com.example.qlbv.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@Component
public class RequestLoggingFilter extends OncePerRequestFilter {
    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        String method = request.getMethod();
        String path = request.getServletPath();
        String queryString = request.getQueryString();
        
        System.out.println("[RequestLoggingFilter] ===== INCOMING REQUEST =====");
        System.out.println("[RequestLoggingFilter] " + method + " " + path + (queryString != null ? "?" + queryString : ""));
        System.out.println("[RequestLoggingFilter] Content-Type: " + request.getContentType());
        System.out.println("[RequestLoggingFilter] Authorization: " + request.getHeader("Authorization"));
        System.out.println("[RequestLoggingFilter] ==========================");
        
        filterChain.doFilter(request, response);
    }
}
