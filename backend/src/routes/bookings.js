const express = require('express');
const router = express.Router();
const Booking = require('../models/Booking');
const Service = require('../models/Service');
const { authenticate, authorizeFarmer } = require('../middleware/auth');

// @route   POST /api/bookings
// @desc    Create a new booking
// @access  Private (Farmer only)
router.post('/', authenticate, authorizeFarmer, async (req, res) => {
  try {
    const {
      serviceId,
      bookingDate,
      startTime,
      endTime,
      duration,
      location,
      specialInstructions
    } = req.body;

    // Validation
    if (!serviceId || !bookingDate || !startTime || !endTime || !duration) {
      return res.status(400).json({
        success: false,
        message: 'Service ID, booking date, start time, end time, and duration are required'
      });
    }

    // Get service
    const service = await Service.findById(serviceId);
    if (!service) {
      return res.status(404).json({
        success: false,
        message: 'Service not found'
      });
    }

    // Check if service is available
    if (service.status !== 'active' || !service.availability.isAvailable) {
      return res.status(400).json({
        success: false,
        message: 'Service is not available for booking'
      });
    }

    // Check availability at requested time
    const bookingDateTime = new Date(bookingDate);
    if (!service.isAvailableAt(bookingDateTime, startTime, endTime)) {
      return res.status(400).json({
        success: false,
        message: 'Service is not available at the requested date and time'
      });
    }

    // Check for conflicting bookings
    const conflictingBooking = await Booking.findOne({
      serviceId,
      bookingDate: bookingDateTime,
      status: { $in: ['pending', 'confirmed'] },
      $or: [
        {
          startTime: { $lt: endTime },
          endTime: { $gt: startTime }
        }
      ]
    });

    if (conflictingBooking) {
      return res.status(400).json({
        success: false,
        message: 'Service is already booked for this time slot'
      });
    }

    // Calculate total price
    const hours = parseFloat(duration);
    const totalPrice = service.pricePerHour * hours;

    // Parse location
    let locationData = {};
    if (location) {
      const loc = typeof location === 'string' ? JSON.parse(location) : location;
      locationData = {
        latitude: loc.latitude || service.location.coordinates[1],
        longitude: loc.longitude || service.location.coordinates[0],
        address: loc.address || service.location.address || ''
      };
    } else {
      locationData = {
        latitude: service.location.coordinates[1],
        longitude: service.location.coordinates[0],
        address: service.location.address || ''
      };
    }

    // Create booking
    const booking = new Booking({
      serviceId,
      farmerId: req.user._id,
      laborerId: service.laborerId,
      bookingDate: bookingDateTime,
      startTime,
      endTime,
      duration: hours,
      totalPrice,
      location: locationData,
      specialInstructions: specialInstructions || '',
      status: 'pending'
    });

    await booking.save();

    // Update service total bookings count
    await Service.findByIdAndUpdate(serviceId, {
      $inc: { totalBookings: 1 }
    });

    // Populate references
    await booking.populate('serviceId');
    await booking.populate('farmerId', 'name email phone');
    await booking.populate('laborerId', 'name email phone');

    res.status(201).json({
      success: true,
      message: 'Booking created successfully',
      data: { booking }
    });
  } catch (error) {
    console.error('Create booking error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
});

// @route   GET /api/bookings/my-bookings
// @desc    Get all bookings for the authenticated user
// @access  Private
router.get('/my-bookings', authenticate, async (req, res) => {
  try {
    const { status, role } = req.query;
    const userId = req.user._id;

    const query = {};
    
    // Filter by user role
    if (req.user.role === 'farmer') {
      query.farmerId = userId;
    } else if (req.user.role === 'laborer') {
      query.laborerId = userId;
    }

    // Filter by status
    if (status) {
      query.status = status;
    }

    const bookings = await Booking.find(query)
      .populate('serviceId', 'title serviceType pricePerHour images')
      .populate('farmerId', 'name email phone')
      .populate('laborerId', 'name email phone')
      .sort({ bookingDate: -1, createdAt: -1 });

    res.status(200).json({
      success: true,
      count: bookings.length,
      data: { bookings }
    });
  } catch (error) {
    console.error('Get my bookings error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
});

// @route   GET /api/bookings/:id
// @desc    Get booking by ID
// @access  Private (Booking participants only)
router.get('/:id', authenticate, async (req, res) => {
  try {
    const booking = await Booking.findById(req.params.id)
      .populate('serviceId')
      .populate('farmerId', 'name email phone')
      .populate('laborerId', 'name email phone');

    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found'
      });
    }

    // Check if user is authorized (farmer or laborer involved in booking)
    const isAuthorized = 
      booking.farmerId._id.toString() === req.user._id.toString() ||
      booking.laborerId._id.toString() === req.user._id.toString();

    if (!isAuthorized) {
      return res.status(403).json({
        success: false,
        message: 'Access denied. You are not authorized to view this booking.'
      });
    }

    res.status(200).json({
      success: true,
      data: { booking }
    });
  } catch (error) {
    console.error('Get booking error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
});

// @route   PUT /api/bookings/:id/status
// @desc    Update booking status
// @access  Private (Booking participants only)
router.put('/:id/status', authenticate, async (req, res) => {
  try {
    const { status } = req.body;
    const allowedStatuses = ['pending', 'confirmed', 'completed', 'cancelled'];

    if (!status || !allowedStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: `Status must be one of: ${allowedStatuses.join(', ')}`
      });
    }

    const booking = await Booking.findById(req.params.id);

    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found'
      });
    }

    // Check authorization
    const isFarmer = booking.farmerId.toString() === req.user._id.toString();
    const isLaborer = booking.laborerId.toString() === req.user._id.toString();

    if (!isFarmer && !isLaborer) {
      return res.status(403).json({
        success: false,
        message: 'Access denied. You are not authorized to update this booking.'
      });
    }

    // Validate status transitions
    if (status === 'confirmed' && booking.status !== 'pending') {
      return res.status(400).json({
        success: false,
        message: 'Only pending bookings can be confirmed'
      });
    }

    if (status === 'completed' && booking.status !== 'confirmed') {
      return res.status(400).json({
        success: false,
        message: 'Only confirmed bookings can be completed'
      });
    }

    if (status === 'cancelled') {
      if (!booking.canBeCancelled()) {
        return res.status(400).json({
          success: false,
          message: 'This booking cannot be cancelled'
        });
      }
    }

    // Update status
    booking.status = status;
    await booking.save();

    // Populate references
    await booking.populate('serviceId');
    await booking.populate('farmerId', 'name email phone');
    await booking.populate('laborerId', 'name email phone');

    res.status(200).json({
      success: true,
      message: 'Booking status updated successfully',
      data: { booking }
    });
  } catch (error) {
    console.error('Update booking status error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
});

// @route   POST /api/bookings/:id/review
// @desc    Add review and rating to a completed booking
// @access  Private (Farmer only)
router.post('/:id/review', authenticate, authorizeFarmer, async (req, res) => {
  try {
    const { rating, comment } = req.body;

    if (!rating || rating < 1 || rating > 5) {
      return res.status(400).json({
        success: false,
        message: 'Rating must be between 1 and 5'
      });
    }

    const booking = await Booking.findById(req.params.id)
      .populate('serviceId');

    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found'
      });
    }

    // Check if booking belongs to the farmer
    if (booking.farmerId.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Access denied. You can only review your own bookings.'
      });
    }

    // Check if booking is completed
    if (booking.status !== 'completed') {
      return res.status(400).json({
        success: false,
        message: 'You can only review completed bookings'
      });
    }

    // Check if review already exists
    if (booking.review && booking.review.rating) {
      return res.status(400).json({
        success: false,
        message: 'Review already exists for this booking'
      });
    }

    // Add review to booking
    booking.review = {
      rating: parseInt(rating),
      comment: comment || '',
      date: new Date()
    };
    await booking.save();

    // Add review to service
    const service = booking.serviceId;
    service.reviews.push({
      farmerId: req.user._id,
      rating: parseInt(rating),
      comment: comment || '',
      date: new Date()
    });
    await service.save(); // This will trigger pre-save hook to recalculate rating

    res.status(200).json({
      success: true,
      message: 'Review added successfully',
      data: { booking, service }
    });
  } catch (error) {
    console.error('Add review error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
});

module.exports = router;

