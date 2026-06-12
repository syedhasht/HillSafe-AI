/// Risk assessment constants used across the application
/// Centralizes risk thresholds and circle rendering parameters
///
/// Thresholds:
///   Low:      < 0.30 (< 30%)
///   Medium:   0.30 – 0.49 (30–50%)
///   High:     0.50 – 0.69 (50–70%)
///   Critical: ≥ 0.70 (≥ 70%)
class RiskConstants {
  /// Geographic radius used for monitored hazard zones on every map.
  static const double hazardZoneRadiusMeters = 20000.0;

  // Risk Score Thresholds (0.0 to 1.0 scale)
  /// Threshold for medium risk classification (>= 0.3 or 30%)
  static const double mediumThreshold = 0.3;

  /// Threshold for high risk classification (>= 0.5 or 50%)
  static const double highThreshold = 0.5;

  /// Threshold for critical risk classification (>= 0.7 or 70%)
  static const double criticalThreshold = 0.7;

  // Circle Rendering Parameters (in meters)
  /// Base radius for risk circles on the map
  static const double baseCircleRadius = 3000.0;

  /// Minimum circle radius for low risk areas
  static const double minCircleRadius = 2000.0;

  /// Maximum circle radius for high risk areas
  static const double maxCircleRadius = 5000.0;

  /// Calculate dynamic circle radius based on risk score
  /// Returns radius in meters, scaled between min and max based on risk level
  static double getCircleRadius(double riskScore) {
    // Scale radius based on risk score
    // Low risk (0.0-0.3): 2000-3000m
    // Medium risk (0.3-0.5): 3000-3500m
    // High risk (0.5-0.7): 3500-4500m
    // Critical risk (0.7-1.0): 4500-5000m
    if (riskScore >= criticalThreshold) {
      final normalized = (riskScore - criticalThreshold) / (1.0 - criticalThreshold);
      return 4500.0 + (normalized * 500.0);
    } else if (riskScore >= highThreshold) {
      final normalized = (riskScore - highThreshold) / (criticalThreshold - highThreshold);
      return 3500.0 + (normalized * 1000.0);
    } else if (riskScore >= mediumThreshold) {
      final normalized = (riskScore - mediumThreshold) / (highThreshold - mediumThreshold);
      return 3000.0 + (normalized * 500.0);
    } else {
      final normalized = riskScore / mediumThreshold;
      return 2000.0 + (normalized * 1000.0);
    }
  }
}

