const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const dotenv = require('dotenv');
const path = require('path');

// Load environment variables from .env file in backend directory
const envPath = path.join(__dirname, '..', '.env');
console.log('🔍 Loading .env from:', envPath);

// Try loading with explicit path first
let envResult = dotenv.config({ path: envPath });

// If that fails, try loading from current working directory
if (envResult.error) {
  console.warn('⚠️  Error loading .env from explicit path, trying current directory...');
  envResult = dotenv.config();
}

// If still fails, try loading from process.cwd()
if (envResult.error) {
  console.warn('⚠️  Error loading .env from current dir, trying process.cwd()...');
  envResult = dotenv.config({ path: path.join(process.cwd(), '.env') });
}

// Log the result
if (envResult.error) {
  console.error('❌ Failed to load .env file:', envResult.error.message);
} else if (envResult.parsed) {
  console.log('✅ .env file loaded successfully');
  console.log('📋 Loaded variables:', Object.keys(envResult.parsed).join(', '));
} else {
  console.warn('⚠️  .env file found but no variables parsed');
}

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// MongoDB Connection
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/kisan_mitra';

// Debug: Log the MongoDB URI (without password for security)
if (process.env.MONGODB_URI) {
  const uriWithoutPassword = process.env.MONGODB_URI.replace(/:[^:@]+@/, ':****@');
  console.log('📝 MongoDB URI loaded:', uriWithoutPassword);
} else {
  console.log('⚠️  MONGODB_URI not found in environment, using default');
}

// MongoDB Connection with retry logic
const connectMongoDB = async () => {
  try {
    await mongoose.connect(MONGODB_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
      serverSelectionTimeoutMS: 30000, // 30 seconds timeout
      socketTimeoutMS: 45000, // Close sockets after 45 seconds of inactivity
    });
    console.log('✅ Connected to MongoDB Atlas');
    console.log('📊 Database:', mongoose.connection.name);
    console.log('🔗 Connection State:', mongoose.connection.readyState === 1 ? 'Connected' : 'Disconnected');
  } catch (err) {
    console.error('❌ MongoDB connection error:', err.message);
    if (err.message.includes('authentication')) {
      console.error('💡 Authentication failed. Check your username and password in the connection string.');
    } else if (err.message.includes('ENOTFOUND') || err.message.includes('getaddrinfo')) {
      console.error('💡 DNS resolution failed. Check your internet connection and MongoDB Atlas cluster URL.');
    } else if (err.message.includes('timeout') || err.message.includes('whitelist') || err.message.includes('Could not connect')) {
      console.error('💡 Connection failed. Please check:');
      console.error('   1. Your IP address is whitelisted in MongoDB Atlas Network Access');
      console.error('      → Go to: https://cloud.mongodb.com/ → Network Access → Add IP Address');
      console.error('      → Add "0.0.0.0/0" for development (allows all IPs)');
      console.error('   2. MongoDB Atlas cluster is running');
      console.error('   3. Your firewall allows outbound connections');
    } else {
      console.error('💡 Make sure your MongoDB Atlas cluster is running and the IP is whitelisted');
    }
    console.error('');
    console.error('⚠️  Server will continue running without MongoDB connection.');
    console.error('⚠️  Some features may not work until MongoDB is connected.');
    console.error('📝 Error details:', err.message);
    // Don't exit - allow server to continue running
  }
};

// Helper function to check MongoDB connection
const isMongoConnected = () => {
  return mongoose.connection.readyState === 1;
};

// Connect to MongoDB (non-blocking)
connectMongoDB();

// Routes
const authRoutes = require('./routes/auth');
const serviceRoutes = require('./routes/services');
const bookingRoutes = require('./routes/bookings');

app.use('/api/auth', authRoutes);
app.use('/api/services', serviceRoutes);
app.use('/api/bookings', bookingRoutes);

// Search History Schema (existing functionality)
const searchHistorySchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  query: { type: String, required: true },
  type: { type: String, required: true, enum: ['text', 'image'] },
  timestamp: { type: Date, default: Date.now },
});

const SearchHistory = mongoose.model('SearchHistory', searchHistorySchema);

// Search History Routes (existing)
app.get('/api/search-history', async (req, res) => {
  if (!isMongoConnected()) {
    return res.status(503).json({ 
      success: false,
      message: 'Database not connected. Please check MongoDB connection.' 
    });
  }
  try {
    const searches = await SearchHistory.find()
      .sort({ timestamp: -1 })
      .limit(50);
    res.json(searches);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.post('/api/search-history', async (req, res) => {
  if (!isMongoConnected()) {
    return res.status(503).json({ 
      success: false,
      message: 'Database not connected. Please check MongoDB connection.' 
    });
  }
  try {
    const { query, type, userId } = req.body;
    const searchHistory = new SearchHistory({
      query,
      type,
      userId: userId || null,
    });
    const savedSearch = await searchHistory.save();
    res.status(201).json(savedSearch);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Server is running',
    timestamp: new Date().toISOString(),
    mongodb: {
      connected: isMongoConnected(),
      state: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected'
    }
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(err.status || 500).json({
    success: false,
    message: err.message || 'Internal server error',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route not found'
  });
});

// Start server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Server is running on port ${PORT}`);
  console.log(`📍 API endpoints available at http://localhost:${PORT}/api`);
});

