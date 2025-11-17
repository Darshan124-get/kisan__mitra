const AWS = require('aws-sdk');
const multer = require('multer');
const path = require('path');
const crypto = require('crypto');
const { URL } = require('url');

// Configure AWS S3
const s3 = new AWS.S3({
  accessKeyId: process.env.AWS_ACCESS_KEY_ID,
  secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  region: process.env.AWS_REGION || 'us-east-1'
});

const BUCKET_NAME = process.env.AWS_S3_BUCKET_NAME;
const DEFAULT_SIGNED_URL_EXPIRY = parseInt(process.env.AWS_SIGNED_URL_EXPIRY || (60 * 60 * 24 * 7), 10); // default 7 days

const extractKeyFromUrl = (imageUrl) => {
  if (!imageUrl) {
    return null;
  }

  // If already a key (no protocol)
  if (!imageUrl.startsWith('http')) {
    return imageUrl.replace(/^\/+/, '');
  }

  try {
    const parsedUrl = new URL(imageUrl);
    if (
      !parsedUrl.hostname ||
      (!parsedUrl.hostname.includes(BUCKET_NAME) &&
        !parsedUrl.hostname.includes('amazonaws.com'))
    ) {
      return null;
    }
    const pathname = parsedUrl.pathname || '';
    return pathname.replace(/^\/+/, '');
  } catch (error) {
    console.warn('⚠️ Failed to parse image URL for key extraction:', imageUrl, error.message);
    return null;
  }
};

const generateSignedUrl = (key, expiresIn = DEFAULT_SIGNED_URL_EXPIRY) => {
  if (!key || !BUCKET_NAME) {
    return null;
  }

  return new Promise((resolve, reject) => {
    s3.getSignedUrl(
      'getObject',
      {
        Bucket: BUCKET_NAME,
        Key: key,
        Expires: expiresIn
      },
      (err, url) => {
        if (err) {
          return reject(err);
        }
        resolve(url);
      }
    );
  });
};

const getSignedImageUrl = async (imageUrl, expiresIn = DEFAULT_SIGNED_URL_EXPIRY) => {
  if (!imageUrl || !BUCKET_NAME || imageUrl.includes('X-Amz-Algorithm=')) {
    return imageUrl;
  }

  const key = extractKeyFromUrl(imageUrl);
  if (!key) {
    return imageUrl;
  }

  try {
    const signedUrl = await generateSignedUrl(key, expiresIn);
    return signedUrl || imageUrl;
  } catch (error) {
    console.error('⚠️ Failed to generate signed image URL:', {
      imageUrl,
      key,
      error: error.message
    });
    return imageUrl;
  }
};

// Configure multer for memory storage (we'll upload directly to S3)
const storage = multer.memoryStorage();

const fileFilter = (req, file, cb) => {
  // Accept all files - no validation
  cb(null, true);
};

const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 5 * 1024 * 1024 // 5MB limit
  }
});

/**
 * Upload a single image to S3
 * @param {Buffer} fileBuffer - The file buffer
 * @param {String} originalName - Original filename
 * @param {String} folder - Folder path in S3 (e.g., 'services', 'profiles')
 * @returns {Promise<String>} - URL of uploaded image
 */
const uploadImage = async (fileBuffer, originalName, folder = 'services') => {
  try {
    if (!BUCKET_NAME) {
      throw new Error('AWS_S3_BUCKET_NAME is not configured');
    }

    if (!process.env.AWS_ACCESS_KEY_ID || !process.env.AWS_SECRET_ACCESS_KEY) {
      throw new Error('AWS credentials are not configured');
    }

    // Ensure fileBuffer is a proper Buffer
    if (!Buffer.isBuffer(fileBuffer)) {
      if (fileBuffer instanceof Uint8Array) {
        fileBuffer = Buffer.from(fileBuffer);
      } else if (Array.isArray(fileBuffer)) {
        fileBuffer = Buffer.from(fileBuffer);
      } else if (typeof fileBuffer === 'string') {
        fileBuffer = Buffer.from(fileBuffer, 'base64');
      } else if (fileBuffer && typeof fileBuffer === 'object') {
        // Handle object case
        if (fileBuffer.data) {
          fileBuffer = Buffer.from(fileBuffer.data);
        } else if (fileBuffer.buffer) {
          fileBuffer = Buffer.from(fileBuffer.buffer);
        } else {
          // Try converting object values
          const bufferData = Object.values(fileBuffer);
          fileBuffer = Buffer.from(bufferData);
        }
      } else {
        throw new Error('Invalid file buffer type: ' + typeof fileBuffer);
      }
    }
    
    // Final check
    if (!Buffer.isBuffer(fileBuffer)) {
      throw new Error('Failed to convert to Buffer');
    }

    // Generate unique filename
    const fileExtension = path.extname(originalName);
    const randomName = crypto.randomBytes(16).toString('hex');
    const fileName = `${folder}/${randomName}${fileExtension}`;

    // Upload to S3
    // Try with ACL first, if it fails due to Block Public Access, retry without ACL
    let params = {
      Bucket: BUCKET_NAME,
      Key: fileName,
      Body: fileBuffer,
      ContentType: getContentType(fileExtension),
      ACL: 'public-read' // Make image publicly accessible
    };

    console.log(`📤 Uploading to S3: Bucket=${BUCKET_NAME}, Key=${fileName}, Region=${process.env.AWS_REGION || 'us-east-1'}`);
    
    let result;
    try {
      result = await s3.upload(params).promise();
    } catch (aclError) {
      // If ACL fails (Block Public Access enabled), try without ACL
      if (aclError.code === 'AccessControlListNotSupported' || 
          aclError.message.includes('Block Public Access') ||
          aclError.code === 'InvalidRequest') {
        console.warn('⚠️ ACL not supported, uploading without ACL. Ensure bucket policy allows public read.');
        params = {
          Bucket: BUCKET_NAME,
          Key: fileName,
          Body: fileBuffer,
          ContentType: getContentType(fileExtension)
          // No ACL - bucket policy should handle public access
        };
        result = await s3.upload(params).promise();
      } else {
        throw aclError;
      }
    }
    
    // Get the URL - try Location first, then construct it manually
    let imageUrl = result.Location;
    
    console.log(`📤 S3 Upload Result:`, {
      Location: result.Location,
      Key: result.Key,
      Bucket: result.Bucket,
      ETag: result.ETag,
      hasLocation: !!result.Location
    });
    
    // If Location is not available, construct it manually
    if (!imageUrl || imageUrl.trim() === '') {
      const region = process.env.AWS_REGION || 'us-east-1';
      // Handle different region formats for S3 URL
      let s3Region = region;
      if (region === 'us-east-1') {
        // us-east-1 doesn't need region in URL
        imageUrl = `https://${BUCKET_NAME}.s3.amazonaws.com/${result.Key}`;
      } else {
        // Other regions need region in URL
        imageUrl = `https://${BUCKET_NAME}.s3.${s3Region}.amazonaws.com/${result.Key}`;
      }
      console.log(`📤 Constructed URL manually: ${imageUrl}`);
    }
    
    console.log(`✅ Successfully uploaded to S3:`, {
      Location: result.Location,
      Key: result.Key,
      Bucket: result.Bucket,
      FinalURL: imageUrl,
      URLType: typeof imageUrl,
      URLLength: imageUrl?.length
    });
    
    if (!imageUrl || imageUrl.trim() === '') {
      throw new Error('S3 upload succeeded but no URL available');
    }
    
    return imageUrl; // Return the public URL
  } catch (error) {
    console.error('❌ Error uploading image to S3:', error);
    console.error('   Bucket:', BUCKET_NAME);
    console.error('   Region:', process.env.AWS_REGION || 'us-east-1');
    console.error('   Has Access Key:', !!process.env.AWS_ACCESS_KEY_ID);
    console.error('   Has Secret Key:', !!process.env.AWS_SECRET_ACCESS_KEY);
    throw new Error(`Failed to upload image: ${error.message}`);
  }
};

/**
 * Upload multiple images to S3
 * @param {Array<{buffer: Buffer, originalname: String}>} files - Array of file objects
 * @param {String} folder - Folder path in S3
 * @returns {Promise<Array<String>>} - Array of uploaded image URLs
 */
const uploadMultipleImages = async (files, folder = 'services') => {
  try {
    const uploadPromises = files.map(file => 
      uploadImage(file.buffer, file.originalname, folder)
    );
    const urls = await Promise.all(uploadPromises);
    return urls;
  } catch (error) {
    console.error('Error uploading multiple images to S3:', error);
    throw new Error(`Failed to upload images: ${error.message}`);
  }
};

/**
 * Delete an image from S3
 * @param {String} imageUrl - The full URL of the image to delete
 * @returns {Promise<Boolean>} - Success status
 */
const deleteImage = async (imageUrl) => {
  try {
    if (!BUCKET_NAME) {
      throw new Error('AWS_S3_BUCKET_NAME is not configured');
    }

    // Extract key from URL
    const urlParts = imageUrl.split('/');
    const key = urlParts.slice(-2).join('/'); // Get folder/filename

    const params = {
      Bucket: BUCKET_NAME,
      Key: key
    };

    await s3.deleteObject(params).promise();
    return true;
  } catch (error) {
    console.error('Error deleting image from S3:', error);
    // Don't throw error - image might not exist or already deleted
    return false;
  }
};

/**
 * Delete multiple images from S3
 * @param {Array<String>} imageUrls - Array of image URLs to delete
 * @returns {Promise<Boolean>} - Success status
 */
const deleteMultipleImages = async (imageUrls) => {
  try {
    if (!BUCKET_NAME || !imageUrls || imageUrls.length === 0) {
      return true;
    }

    const deletePromises = imageUrls.map(url => deleteImage(url));
    await Promise.all(deletePromises);
    return true;
  } catch (error) {
    console.error('Error deleting multiple images from S3:', error);
    return false;
  }
};

/**
 * Get content type based on file extension
 * @param {String} extension - File extension
 * @returns {String} - MIME type
 */
const getContentType = (extension) => {
  const contentTypes = {
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.png': 'image/png',
    '.gif': 'image/gif',
    '.webp': 'image/webp'
  };
  return contentTypes[extension.toLowerCase()] || 'image/jpeg';
};

/**
 * Compress image (basic validation - for production, use sharp or jimp)
 * @param {Buffer} fileBuffer - Image buffer
 * @returns {Buffer} - Compressed buffer (placeholder - implement actual compression)
 */
const compressImage = async (fileBuffer) => {
  // TODO: Implement actual image compression using sharp or jimp
  // For now, return as-is
  return fileBuffer;
};

module.exports = {
  s3,
  upload,
  uploadImage,
  uploadMultipleImages,
  deleteImage,
  deleteMultipleImages,
  compressImage,
  getSignedImageUrl
};

