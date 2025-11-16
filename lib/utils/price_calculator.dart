class PriceCalculator {
  static double calculateBookingPrice({
    required double pricePerHour,
    required double duration, // in hours
  }) {
    return pricePerHour * duration;
  }

  static double calculateDailyPrice({
    required double pricePerHour,
    required double hoursPerDay,
  }) {
    return pricePerHour * hoursPerDay;
  }

  static String formatPrice(double price) {
    if (price >= 100000) {
      return '₹${(price / 100000).toStringAsFixed(1)}L';
    } else if (price >= 1000) {
      return '₹${(price / 1000).toStringAsFixed(1)}K';
    } else {
      return '₹${price.toStringAsFixed(0)}';
    }
  }
}

