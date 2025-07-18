//
//  PerformanceMonitor.swift
//  MouseQuicker
//
//  Created by syferie on 2025/7/17.
//

import Foundation
import os.log

/// Performance monitoring and optimization utilities
class PerformanceMonitor: ObservableObject {
    
    /// Singleton instance
    static let shared = PerformanceMonitor()
    
    /// Performance metrics
    @Published var metrics: PerformanceMetrics = PerformanceMetrics()
    
    /// Logger for performance events
    private let logger = Logger(subsystem: "com.syferie.mousequicker", category: "Performance")
    
    /// Timer for periodic metrics collection
    private var metricsTimer: Timer?
    
    private init() {
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Monitoring Control
    
    /// Start performance monitoring
    func startMonitoring() {
        metricsTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.collectMetrics()
        }
        logger.info("Performance monitoring started")
    }
    
    /// Stop performance monitoring
    func stopMonitoring() {
        metricsTimer?.invalidate()
        metricsTimer = nil
        logger.info("Performance monitoring stopped")
    }
    
    // MARK: - Metrics Collection
    
    /// Collect current performance metrics
    private func collectMetrics() {
        let processInfo = ProcessInfo.processInfo
        
        // Memory usage
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let memoryUsage = Double(info.resident_size) / 1024.0 / 1024.0 // MB
            metrics.memoryUsage = memoryUsage
        }
        
        // CPU usage (simplified)
        metrics.cpuUsage = Double(processInfo.thermalState.rawValue)
        
        // Update timestamp
        metrics.lastUpdated = Date()
        
        // Log if memory usage is high
        if metrics.memoryUsage > 100.0 {
            logger.warning("High memory usage detected: \(self.metrics.memoryUsage, privacy: .public) MB")
        }
    }
    
    // MARK: - Performance Timing
    
    /// Measure execution time of a block
    /// - Parameters:
    ///   - label: Label for the measurement
    ///   - block: Block to measure
    /// - Returns: Result of the block execution
    func measure<T>(label: String, block: () throws -> T) rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try block()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        logger.info("Performance: \(label, privacy: .public) took \(timeElapsed * 1000, privacy: .public) ms")
        
        // Record timing
        metrics.recordTiming(label: label, duration: timeElapsed)
        
        return result
    }
    
    /// Measure async execution time
    /// - Parameters:
    ///   - label: Label for the measurement
    ///   - block: Async block to measure
    /// - Returns: Result of the block execution
    func measureAsync<T>(label: String, block: () async throws -> T) async rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await block()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        logger.info("Performance: \(label, privacy: .public) took \(timeElapsed * 1000, privacy: .public) ms")
        
        // Record timing
        metrics.recordTiming(label: label, duration: timeElapsed)
        
        return result
    }
    
    // MARK: - Optimization Suggestions
    
    /// Get performance optimization suggestions
    /// - Returns: Array of optimization suggestions
    func getOptimizationSuggestions() -> [OptimizationSuggestion] {
        var suggestions: [OptimizationSuggestion] = []
        
        // Memory optimization
        if metrics.memoryUsage > 50.0 {
            suggestions.append(OptimizationSuggestion(
                type: .memory,
                priority: .medium,
                description: "内存使用较高，考虑优化数据结构或减少缓存"
            ))
        }
        
        // Event monitoring optimization
        if let eventTiming = metrics.timings["EventMonitor"] {
            if eventTiming.averageDuration > 0.01 { // 10ms
                suggestions.append(OptimizationSuggestion(
                    type: .performance,
                    priority: .high,
                    description: "事件监听响应时间较慢，考虑优化事件处理逻辑"
                ))
            }
        }
        
        // Menu rendering optimization
        if let menuTiming = metrics.timings["PieMenuRender"] {
            if menuTiming.averageDuration > 0.016 { // 16ms (60fps)
                suggestions.append(OptimizationSuggestion(
                    type: .ui,
                    priority: .medium,
                    description: "菜单渲染时间超过16ms，可能影响流畅度"
                ))
            }
        }
        
        return suggestions
    }
    
    /// Reset all metrics
    func resetMetrics() {
        metrics = PerformanceMetrics()
        logger.info("Performance metrics reset")
    }

    /// 定期清理旧的性能数据，防止内存累积
    func cleanupOldMetrics() {
        // 限制每个操作的计时记录数量
        let maxRecordsPerOperation = 100

        for (key, timing) in metrics.timings {
            if timing.measurementCount > maxRecordsPerOperation {
                // 重置计时数据，保留平均值
                let avgDuration = timing.averageDuration
                metrics.timings[key] = TimingData(duration: avgDuration)
            }
        }

        logger.debug("Performance metrics cleaned up")
    }
}

// MARK: - Supporting Types

/// Performance metrics data structure
struct PerformanceMetrics {
    var memoryUsage: Double = 0.0 // MB
    var cpuUsage: Double = 0.0 // Percentage
    var timings: [String: TimingData] = [:]
    var lastUpdated: Date = Date()
    
    /// Record a timing measurement
    mutating func recordTiming(label: String, duration: TimeInterval) {
        if var existing = timings[label] {
            existing.addMeasurement(duration)
            timings[label] = existing
        } else {
            timings[label] = TimingData(duration: duration)
        }
    }
}

/// Timing data for performance measurements
struct TimingData {
    var totalDuration: TimeInterval
    var measurementCount: Int
    var minDuration: TimeInterval
    var maxDuration: TimeInterval
    
    var averageDuration: TimeInterval {
        return measurementCount > 0 ? totalDuration / Double(measurementCount) : 0
    }
    
    init(duration: TimeInterval) {
        self.totalDuration = duration
        self.measurementCount = 1
        self.minDuration = duration
        self.maxDuration = duration
    }
    
    mutating func addMeasurement(_ duration: TimeInterval) {
        totalDuration += duration
        measurementCount += 1
        minDuration = min(minDuration, duration)
        maxDuration = max(maxDuration, duration)
    }
}

/// Optimization suggestion
struct OptimizationSuggestion {
    enum SuggestionType {
        case memory
        case performance
        case ui
        case network
    }
    
    enum Priority {
        case low
        case medium
        case high
        case critical
    }
    
    let type: SuggestionType
    let priority: Priority
    let description: String
}

// MARK: - Performance Macros

/// Convenience function for measuring performance
func withPerformanceMeasurement<T>(label: String, block: () throws -> T) rethrows -> T {
    return try PerformanceMonitor.shared.measure(label: label, block: block)
}

/// Convenience function for measuring async performance
func withAsyncPerformanceMeasurement<T>(label: String, block: () async throws -> T) async rethrows -> T {
    return try await PerformanceMonitor.shared.measureAsync(label: label, block: block)
}
