const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const dotenv = require('dotenv');

dotenv.config();

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// MongoDB Connection
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/kisan_mitra', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
.then(() => console.log('Connected to MongoDB'))
.catch((err) => console.error('MongoDB connection error:', err));

// Search History Schema
const searchHistorySchema = new mongoose.Schema({
  query: { type: String, required: true },
  type: { type: String, required: true, enum: ['text', 'image'] },
  timestamp: { type: Date, default: Date.now },
});

const SearchHistory = mongoose.model('SearchHistory', searchHistorySchema);

// Routes
app.get('/api/search-history', async (req, res) => {
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
  try {
    const { query, type } = req.body;
    const searchHistory = new SearchHistory({
      query,
      type,
    });
    const savedSearch = await searchHistory.save();
    res.status(201).json(savedSearch);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

// Start server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
}); 