class AwsConfig {
  // These should be loaded from environment variables
  // For now, using placeholder values
  static const String bucketName = 'your-bucket-name';
  static const String region = 'us-east-1';
  static const String accessKeyId = 'your-access-key-id';
  static const String secretAccessKey = 'your-secret-access-key';

  // Load from environment variables if available
  static String getBucketName() {
    // TODO: Load from .env file using flutter_dotenv
    return bucketName;
  }

  static String getRegion() {
    // TODO: Load from .env file
    return region;
  }
}

