const express = require('express');
const router = express.Router();
const Service = require('../models/Service');
const { authenticate, authorizeLaborer, authorizeServiceOwner } = require('../middleware/auth');
const { upload, uploadImage, uploadMultipleImages, deleteMultipleImages } = require('../config/s3');

// @route   POST /api/services
// @desc    Create a new service
// @access  Private (Laborer only)
router.post('/', authenticate, authorizeLaborer, upload.array('images', 10), async (req, res) => {
  try {
    const {
      serviceType,
      title,
      description,
      pricePerHour,
      pricePerDay,
      location,
      availability,
      specifications,
      images // URLs if provided directly
    } = req.body;

    // Validation
    if (!serviceType || !title || !pricePerHour) {
      return res.status(400).json({
        success: false,
        message: 'Service type, title, and price per hour are required'
      });
    }

    // Parse location
    let locationData = {};
    if (location) {
      const loc = typeof location === 'string' ? JSON.parse(location) : location;
      if (loc.coordinates && loc.coordinates.length === 2) {
        locationData = {
          type: 'Point',
          coordinates: [loc.coordinates[0], loc.coordinates[1]], // [longitude, latitude]
          address: loc.address || '',
          village: loc.village || '',
          district: loc.district || '',
          state: loc.state || ''
        };
      }
    }

    // Parse availability
    let availabilityData = {
      isAvailable: true,
      schedule: [],
      unavailableDates: []
    };
    if (availability) {
      const avail = typeof availability === 'string' ? JSON.parse(availability) : availability;
      availabilityData = {
        isAvailable: avail.isAvailable !== undefined ? avail.isAvailable : true,
        schedule: avail.schedule || [],
        unavailableDates: (avail.unavailableDates || []).map(date => new Date(date))
      };
    }

    // Parse specifications
    let specificationsData = {};
    if (specifications) {
      specificationsData = typeof specifications === 'string' ? JSON.parse(specifications) : specifications;
    }

    // Handle image uploads
    let imageUrls = [];
    if (images && typeof images === 'string') {
      // If images are provided as JSON string array
      imageUrls = JSON.parse(images);
    } else if (Array.isArray(images)) {
      imageUrls = images;
    }

    // Upload files from multer if any
    if (req.files && req.files.length > 0) {
      const uploadedUrls = await uploadMultipleImages(req.files, 'services');
      imageUrls = [...imageUrls, ...uploadedUrls];
    }

    // Create service
    const service = new Service({
      laborerId: req.user._id,
      serviceType,
      title,
      description: description || '',
      pricePerHour: parseFloat(pricePerHour),
      pricePerDay: pricePerDay ? parseFloat(pricePerDay) : undefined,
      location: locationData,
      availability: availabilityData,
      images: imageUrls,
      specifications: specificationsData,
      status: 'active'
    });

    await service.save();

    res.status(201).json({
      success: true,
      message: 'Service created successfully',
      data: { service }
    });
  } catch (error) {
    console.error('Create service error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
});

// @route   GET /api/services/my-services
// @desc    Get all services created by the authenticated laborer
// @access  Private (Laborer only)
router.get('/my-services', authenticate, authorizeLaborer, async (req, res) => {
  try {
    const services = await Service.find({ laborerId: req.user._id })
      .sort({ createdAt: -1 })
      .populate('laborerId', 'name email phone');

    res.status(200).json({
      success: true,
      count: services.length,
      data: { services }
    });
  } catch (error) {
    console.error('Get my services error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
});

// @route   GET /api/services/nearby
// @desc    Get nearby services using geospatial query
// @access  Public
router.get('/nearby', async (req, res) => {
  try {
    const { latitude, longitude, radius = 10, serviceType, limit = 20 } = req.query;

    if (!latitude || !longitude) {
      return res.status(400).json({
        success: false,
        message: 'Latitude and longitude are required'
      });
    }

    const lat = parseFloat(latitude);
    const lon = parseFloat(longitude);
    const rad = parseFloat(radius) * 1000; // Convert km to meters

    const query = {
      location: {
        $near: {
          $geometry: {
            type: 'Point',
            coordinates: [lon, lat] // [longitude, latitude]
          },
          $maxDistance: rad
        }
      },
      status: 'active',
      'availability.isAvailable': true
    };

    if (serviceType) {
      query.serviceType = serviceType;
    }

    const services = await Service.find(query)
      .populate('laborerId', 'name email phone')
      .limit(parseInt(limit));

    res.status(200).json({
      success: true,
      count: services.length,
      data: { services }
    });
  } catch (error) {
    console.error('Get nearby services error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
});

// @route   POST /api/services/upload-image
// @desc    Upload a single image to S3
// @access  Private (Laborer only)
router.post('/upload-image', authenticate, authorizeLaborer, upload.single('image'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No image file provided'
      });
    }

    const imageUrl = await uploadImage(req.file, 'services');

    res.status(200).json({
      success: true,
      data: { imageUrl }
    });
  } catch (error) {
    console.error('Upload image error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
});

// @route   GET /api/services/search
// @desc    Search services
// @access  Public
router.get('/search', async (req, res) => {
  try {
    const { q, serviceType, minPrice, maxPrice, latitude, longitude, radius, page = 1, limit = 20 } = req.query;

    const query = { status: 'active' };

    if (q) {
      query.$or = [
        { title: { $regex: q, $options: 'i' } },
        { description: { $regex: q, $options: 'i' } }
      ];
    }

    if (serviceType) {
      query.serviceType = serviceType;
    }

    if (minPrice || maxPrice) {
      query.pricePerHour = {};
      if (minPrice) query.pricePerHour.$gte = parseFloat(minPrice);
      if (maxPrice) query.pricePerHour.$lte = parseFloat(maxPrice);
    }

    if (latitude && longitude && radius) {
      const lat = parseFloat(latitude);
      const lon = parseFloat(longitude);
      const rad = parseFloat(radius) * 1000;

      query.location = {
        $near: {
          $geometry: {
            type: 'Point',
            coordinates: [lon, lat]
          },
          $maxDistance: rad
        }
      };
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const services = await Service.find(query)
      .populate('laborerId', 'name email phone')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await Service.countDocuments(query);

    res.status(200).json({
      success: true,
      count: services.length,
      total,
      page: parseInt(page),
      pages: Math.ceil(total / parseInt(limit)),
      data: { services }
    });
  } catch (error) {
    console.error('Search services error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
});

// @route   GET /api/services/:id
// @desc    Get service by ID
// @access  Public
router.get('/:id', async (req, res) => {
  try {
    const service = await Service.findById(req.params.id)
      .populate('laborerId', 'name email phone')
      .populate('reviews.farmerId', 'name');

    if (!service) {
      return res.status(404).json({
        success: false,
        message: 'Service not found'
      });
    }

    res.status(200).json({
      success: true,
      data: { service }
    });
  } catch (error) {
    console.error('Get service error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
});

// @route   PUT /api/services/:id
// @desc    Update service
// @access  Private (Service owner only)
router.put('/:id', authenticate, authorizeServiceOwner, upload.array('images', 10), async (req, res) => {
  try {
    const {
      title,
      description,
      pricePerHour,
      pricePerDay,
      location,
      availability,
      specifications,
      images,
      status
    } = req.body;

    const updateData = {};

    if (title !== undefined) updateData.title = title;
    if (description !== undefined) updateData.description = description;
    if (pricePerHour !== undefined) updateData.pricePerHour = parseFloat(pricePerHour);
    if (pricePerDay !== undefined) updateData.pricePerDay = parseFloat(pricePerDay);
    if (status !== undefined) updateData.status = status;

    // Parse and update location
    if (location) {
      const loc = typeof location === 'string' ? JSON.parse(location) : location;
      if (loc.coordinates && loc.coordinates.length === 2) {
        updateData.location = {
          type: 'Point',
          coordinates: [loc.coordinates[0], loc.coordinates[1]],
          address: loc.address || req.service.location.address,
          village: loc.village || req.service.location.village,
          district: loc.district || req.service.location.district,
          state: loc.state || req.service.location.state
        };
      }
    }

    // Parse and update availability
    if (availability) {
      const avail = typeof availability === 'string' ? JSON.parse(availability) : availability;
      updateData.availability = {
        isAvailable: avail.isAvailable !== undefined ? avail.isAvailable : req.service.availability.isAvailable,
        schedule: avail.schedule || req.service.availability.schedule,
        unavailableDates: (avail.unavailableDates || []).map(date => new Date(date))
      };
    }

    // Parse and update specifications
    if (specifications) {
      updateData.specifications = typeof specifications === 'string' 
        ? JSON.parse(specifications) 
        : specifications;
    }

    // Handle image updates
    if (images || req.files) {
      let imageUrls = req.service.images || [];
      
      // Parse new image URLs if provided
      if (images) {
        const newImages = typeof images === 'string' ? JSON.parse(images) : images;
        imageUrls = Array.isArray(newImages) ? newImages : imageUrls;
      }

      // Upload new files if any
      if (req.files && req.files.length > 0) {
        const uploadedUrls = await uploadMultipleImages(req.files, 'services');
        imageUrls = [...imageUrls, ...uploadedUrls];
      }

      updateData.images = imageUrls;
    }

    const service = await Service.findByIdAndUpdate(
      req.params.id,
      { $set: updateData },
      { new: true, runValidators: true }
    );

    res.status(200).json({
      success: true,
      message: 'Service updated successfully',
      data: { service }
    });
  } catch (error) {
    console.error('Update service error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
});

// @route   DELETE /api/services/:id
// @desc    Delete service
// @access  Private (Service owner only)
router.delete('/:id', authenticate, authorizeServiceOwner, async (req, res) => {
  try {
    // Delete images from S3
    if (req.service.images && req.service.images.length > 0) {
      await deleteMultipleImages(req.service.images);
    }

    await Service.findByIdAndDelete(req.params.id);

    res.status(200).json({
      success: true,
      message: 'Service deleted successfully'
    });
  } catch (error) {
    console.error('Delete service error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
});

// @route   PUT /api/services/:id/availability
// @desc    Update service availability schedule
// @access  Private (Service owner only)
router.put('/:id/availability', authenticate, authorizeServiceOwner, async (req, res) => {
  try {
    const { isAvailable, schedule, unavailableDates } = req.body;

    const updateData = {};
    if (isAvailable !== undefined) updateData['availability.isAvailable'] = isAvailable;
    if (schedule) {
      updateData['availability.schedule'] = typeof schedule === 'string' 
        ? JSON.parse(schedule) 
        : schedule;
    }
    if (unavailableDates) {
      updateData['availability.unavailableDates'] = (typeof unavailableDates === 'string' 
        ? JSON.parse(unavailableDates) 
        : unavailableDates).map(date => new Date(date));
    }

    const service = await Service.findByIdAndUpdate(
      req.params.id,
      { $set: updateData },
      { new: true }
    );

    res.status(200).json({
      success: true,
      message: 'Availability updated successfully',
      data: { service }
    });
  } catch (error) {
    console.error('Update availability error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
});

// @route   PUT /api/services/:id/location
// @desc    Update service location
// @access  Private (Service owner only)
router.put('/:id/location', authenticate, authorizeServiceOwner, async (req, res) => {
  try {
    const { coordinates, address, village, district, state } = req.body;

    if (!coordinates || !Array.isArray(coordinates) || coordinates.length !== 2) {
      return res.status(400).json({
        success: false,
        message: 'Valid coordinates are required'
      });
    }

    const locationData = {
      type: 'Point',
      coordinates: [coordinates[0], coordinates[1]], // [longitude, latitude]
      address: address || '',
      village: village || '',
      district: district || '',
      state: state || ''
    };

    const service = await Service.findByIdAndUpdate(
      req.params.id,
      { $set: { location: locationData } },
      { new: true }
    );

    res.status(200).json({
      success: true,
      message: 'Location updated successfully',
      data: { service }
    });
  } catch (error) {
    console.error('Update location error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
});

// @route   GET /api/services
// @desc    Get all services with filters
// @access  Public
// NOTE: This route must be defined AFTER specific routes like /nearby, /my-services, etc.
router.get('/', async (req, res) => {
  try {
    const {
      serviceType,
      minPrice,
      maxPrice,
      latitude,
      longitude,
      radius, // in kilometers
      isAvailable,
      status,
      search,
      page = 1,
      limit = 20
    } = req.query;

    const query = {};

    // Filter by service type
    if (serviceType) {
      query.serviceType = serviceType;
    }

    // Filter by price range
    if (minPrice || maxPrice) {
      query.pricePerHour = {};
      if (minPrice) query.pricePerHour.$gte = parseFloat(minPrice);
      if (maxPrice) query.pricePerHour.$lte = parseFloat(maxPrice);
    }

    // Filter by availability
    if (isAvailable === 'true') {
      query['availability.isAvailable'] = true;
      query.status = 'active';
    }

    // Filter by status
    if (status) {
      query.status = status;
    } else {
      query.status = 'active'; // Default to active services
    }

    // Text search
    if (search) {
      query.$or = [
        { title: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } }
      ];
    }

    // Geospatial query for nearby services
    if (latitude && longitude && radius) {
      const lat = parseFloat(latitude);
      const lon = parseFloat(longitude);
      const rad = parseFloat(radius) * 1000; // Convert km to meters

      query.location = {
        $near: {
          $geometry: {
            type: 'Point',
            coordinates: [lon, lat] // [longitude, latitude]
          },
          $maxDistance: rad
        }
      };
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const services = await Service.find(query)
      .populate('laborerId', 'name email phone')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await Service.countDocuments(query);

    res.status(200).json({
      success: true,
      count: services.length,
      total,
      page: parseInt(page),
      pages: Math.ceil(total / parseInt(limit)),
      data: { services }
    });
  } catch (error) {
    console.error('Get services error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
});

// @route   POST /api/services/upload-image
// @desc    Upload a single image to S3
// @access  Private (Laborer only)
router.post('/upload-image', authenticate, authorizeLaborer, upload.single('image'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No image file provided'
      });
    }

    console.log('📤 Received image upload request:', {
      filename: req.file.originalname,
      size: req.file.size,
      mimetype: req.file.mimetype
    });

    // Upload to S3 using uploadImage function
    const imageUrl = await uploadImage(req.file.buffer, req.file.originalname, 'services');
    
    if (imageUrl) {
      console.log('✅ Image uploaded successfully:', imageUrl);
      res.status(200).json({
        success: true,
        url: imageUrl
      });
    } else {
      throw new Error('Upload completed but no URL returned');
    }
  } catch (error) {
    console.error('❌ Upload image error:', error);
    console.error('   Error details:', {
      message: error.message,
      code: error.code,
      statusCode: error.statusCode,
      region: error.region
    });
    res.status(500).json({
      success: false,
      message: 'Failed to upload image',
      error: error.message
    });
  }
});

// @route   GET /api/services/search
// @desc    Search services with text and filters
// @access  Public
router.get('/search', async (req, res) => {
  try {
    const {
      q, // search query
      serviceType,
      minPrice,
      maxPrice,
      latitude,
      longitude,
      radius,
      page = 1,
      limit = 20
    } = req.query;

    const query = {
      status: 'active',
      'availability.isAvailable': true
    };

    // Text search
    if (q) {
      query.$or = [
        { title: { $regex: q, $options: 'i' } },
        { description: { $regex: q, $options: 'i' } },
        { 'specifications.skills': { $regex: q, $options: 'i' } }
      ];
    }

    // Filter by service type
    if (serviceType) {
      query.serviceType = serviceType;
    }

    // Filter by price range
    if (minPrice || maxPrice) {
      query.pricePerHour = {};
      if (minPrice) query.pricePerHour.$gte = parseFloat(minPrice);
      if (maxPrice) query.pricePerHour.$lte = parseFloat(maxPrice);
    }

    // Geospatial query
    if (latitude && longitude && radius) {
      const lat = parseFloat(latitude);
      const lon = parseFloat(longitude);
      const rad = parseFloat(radius) * 1000;

      query.location = {
        $near: {
          $geometry: {
            type: 'Point',
            coordinates: [lon, lat]
          },
          $maxDistance: rad
        }
      };
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const services = await Service.find(query)
      .populate('laborerId', 'name email phone')
      .sort({ rating: -1, createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await Service.countDocuments(query);

    res.status(200).json({
      success: true,
      count: services.length,
      total,
      page: parseInt(page),
      pages: Math.ceil(total / parseInt(limit)),
      data: { services }
    });
  } catch (error) {
    console.error('Search services error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
});

module.exports = router;

