/// Risk assessment constants used across the application
/// Centralizes risk thresholds and circle rendering parameters
class RiskConstants {
  // Risk Score Thresholds (0.0 to 1.0 scale)
  /// Threshold below which the app should show "No Risk" (< 0.15 or 15%)
  static const double noRiskThreshold = 0.15;

  /// Threshold for high risk classification (>= 0.7 or 70%)
  static const double highRiskThreshold = 0.7;
  
  /// Threshold for moderate risk classification (>= 0.3 or 30%)
  static const double moderateRiskThreshold = 0.3;
  
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
    // Moderate risk (0.3-0.7): 3000-4000m
    // High risk (0.7-1.0): 4000-5000m
    if (riskScore >= highRiskThreshold) {
      // High risk: 4000-5000m
      final normalized = (riskScore - highRiskThreshold) / (1.0 - highRiskThreshold);
      return 4000.0 + (normalized * 1000.0);
    } else if (riskScore >= moderateRiskThreshold) {
      // Moderate risk: 3000-4000m
      final normalized = (riskScore - moderateRiskThreshold) / (highRiskThreshold - moderateRiskThreshold);
      return 3000.0 + (normalized * 1000.0);
    } else {
      // Low risk: 2000-3000m
      final normalized = riskScore / moderateRiskThreshold;
      return 2000.0 + (normalized * 1000.0);
    }
  }
}

