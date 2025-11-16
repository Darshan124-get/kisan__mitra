const mongoose = require('mongoose');

const serviceSchema = new mongoose.Schema({
  laborerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'Laborer ID is required'],
    index: true
  },
  serviceType: {
    type: String,
    required: [true, 'Service type is required'],
    enum: ['tractor', 'cultivator', 'worker_individual', 'worker_group', 'other'],
    index: true
  },
  title: {
    type: String,
    required: [true, 'Title is required'],
    trim: true,
    maxlength: [200, 'Title cannot exceed 200 characters']
  },
  description: {
    type: String,
    trim: true,
    maxlength: [2000, 'Description cannot exceed 2000 characters']
  },
  pricePerHour: {
    type: Number,
    required: [true, 'Price per hour is required'],
    min: [0, 'Price cannot be negative']
  },
  pricePerDay: {
    type: Number,
    min: [0, 'Price cannot be negative']
  },
  location: {
    type: {
      type: String,
      enum: ['Point'],
      default: 'Point'
    },
    coordinates: {
      type: [Number], // [longitude, latitude]
      required: true,
      validate: {
        validator: function(v) {
          return v.length === 2 && 
                 v[0] >= -180 && v[0] <= 180 && 
                 v[1] >= -90 && v[1] <= 90;
        },
        message: 'Invalid coordinates'
      }
    },
    address: {
      type: String,
      trim: true
    },
    village: {
      type: String,
      trim: true
    },
    district: {
      type: String,
      trim: true
    },
    state: {
      type: String,
      trim: true
    }
  },
  availability: {
    isAvailable: {
      type: Boolean,
      default: true
    },
    schedule: [{
      day: {
        type: String,
        enum: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
      },
      startTime: {
        type: String,
        match: [/^([0-1][0-9]|2[0-3]):[0-5][0-9]$/, 'Invalid time format (HH:MM)']
      },
      endTime: {
        type: String,
        match: [/^([0-1][0-9]|2[0-3]):[0-5][0-9]$/, 'Invalid time format (HH:MM)']
      },
      isAvailable: {
        type: Boolean,
        default: true
      }
    }],
    unavailableDates: [{
      type: Date
    }]
  },
  images: [{
    type: String, // URLs to images stored in S3
    trim: true
  }],
  specifications: {
    // For tractors/cultivators
    modelYear: String,
    enginePower: String,
    fuelType: {
      type: String,
      enum: ['Diesel', 'Petrol', 'Electric', 'Other']
    },
    transmission: {
      type: String,
      enum: ['Manual', 'Automatic', 'Semi-Automatic']
    },
    features: [String],
    maintenanceStatus: {
      type: String,
      enum: ['Excellent', 'Good', 'Fair', 'Poor']
    },
    lastServiceDate: Date,
    // For workers
    experience: String,
    skills: [String],
    teamSize: {
      type: Number,
      min: 1
    },
    teamMembers: [{
      name: String,
      role: String
    }]
  },
  rating: {
    type: Number,
    default: 0,
    min: 0,
    max: 5
  },
  totalBookings: {
    type: Number,
    default: 0
  },
  reviews: [{
    farmerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    rating: {
      type: Number,
      required: true,
      min: 1,
      max: 5
    },
    comment: {
      type: String,
      trim: true,
      maxlength: [500, 'Comment cannot exceed 500 characters']
    },
    date: {
      type: Date,
      default: Date.now
    }
  }],
  status: {
    type: String,
    enum: ['active', 'inactive', 'pending'],
    default: 'active',
    index: true
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
});

// Create geospatial index for location-based queries
serviceSchema.index({ 'location': '2dsphere' });

// Create compound indexes for common queries
serviceSchema.index({ serviceType: 1, status: 1 });
serviceSchema.index({ laborerId: 1, status: 1 });
serviceSchema.index({ 'availability.isAvailable': 1, status: 1 });

// Update updatedAt before saving
serviceSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

// Calculate average rating before saving
serviceSchema.pre('save', function(next) {
  if (this.reviews && this.reviews.length > 0) {
    const sum = this.reviews.reduce((acc, review) => acc + review.rating, 0);
    this.rating = Math.round((sum / this.reviews.length) * 10) / 10; // Round to 1 decimal place
  } else {
    this.rating = 0;
  }
  next();
});

// Method to check if service is available at a specific date and time
serviceSchema.methods.isAvailableAt = function(date, startTime, endTime) {
  if (!this.availability.isAvailable || this.status !== 'active') {
    return false;
  }

  // Check if date is in unavailable dates
  const dateStr = date.toISOString().split('T')[0];
  const isUnavailable = this.availability.unavailableDates.some(unavailDate => {
    return unavailDate.toISOString().split('T')[0] === dateStr;
  });
  if (isUnavailable) {
    return false;
  }

  // Check schedule for the day of week
  const dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  const dayName = dayNames[date.getDay()];
  const daySchedule = this.availability.schedule.find(s => s.day === dayName);

  if (!daySchedule || !daySchedule.isAvailable) {
    return false;
  }

  // Check if requested time overlaps with available time
  if (daySchedule.startTime && daySchedule.endTime) {
    const requestedStart = startTime.split(':').map(Number);
    const requestedEnd = endTime.split(':').map(Number);
    const availableStart = daySchedule.startTime.split(':').map(Number);
    const availableEnd = daySchedule.endTime.split(':').map(Number);

    const requestedStartMinutes = requestedStart[0] * 60 + requestedStart[1];
    const requestedEndMinutes = requestedEnd[0] * 60 + requestedEnd[1];
    const availableStartMinutes = availableStart[0] * 60 + availableStart[1];
    const availableEndMinutes = availableEnd[0] * 60 + availableEnd[1];

    if (requestedStartMinutes < availableStartMinutes || requestedEndMinutes > availableEndMinutes) {
      return false;
    }
  }

  return true;
};

const Service = mongoose.model('Service', serviceSchema);

module.exports = Service;

