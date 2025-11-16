# Kisan Mitra Backend

Backend server for Kisan Mitra application built with Node.js, Express, and MongoDB.

## Features

- User authentication (Signup, Signin)
- Role-based access control (Farmer, Laborer)
- JWT token authentication
- MongoDB database integration
- Search history tracking

## Prerequisites

- Node.js (v14 or higher)
- MongoDB (local or cloud instance)
- npm or yarn

## Installation

1. Install dependencies:
```bash
npm install
```

2. Create a `.env` file in the backend directory:
```bash
cp .env.example .env
```

3. Update `.env` with your configuration:
```
MONGODB_URI=mongodb://localhost:27017/kisan_mitra
JWT_SECRET=your-super-secret-jwt-key
JWT_EXPIRE=30d
PORT=3000
NODE_ENV=development
```

## Running the Server

### Development mode (with auto-reload):
```bash
npm run dev
```

### Production mode:
```bash
npm start
```

The server will start on `http://localhost:3000`

## API Endpoints

### Authentication

#### POST `/api/auth/signup`
Register a new user

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123",
  "role": "farmer",
  "name": "John Doe",
  "phone": "+1234567890"
}
```

**Response:**
```json
{
  "success": true,
  "message": "User registered successfully",
  "data": {
    "user": {
      "id": "user_id",
      "email": "user@example.com",
      "role": "farmer",
      "name": "John Doe",
      "phone": "+1234567890",
      "isVerified": false
    },
    "token": "jwt_token_here"
  }
}
```

#### POST `/api/auth/signin`
Login user

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {
      "id": "user_id",
      "email": "user@example.com",
      "role": "farmer",
      "name": "John Doe",
      "phone": "+1234567890",
      "isVerified": false
    },
    "token": "jwt_token_here"
  }
}
```

#### GET `/api/auth/me`
Get current user (requires authentication)

**Headers:**
```
Authorization: Bearer <token>
```

#### PUT `/api/auth/profile`
Update user profile (requires authentication)

**Headers:**
```
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "name": "Updated Name",
  "phone": "+9876543210"
}
```

### Search History

#### GET `/api/search-history`
Get search history

#### POST `/api/search-history`
Save search history

**Request Body:**
```json
{
  "query": "Plant disease",
  "type": "text",
  "userId": "user_id"
}
```

## User Roles

- `farmer`: Access to farmer-specific features
- `laborer`: Access to laborer-specific features

## Security

- Passwords are hashed using bcryptjs
- JWT tokens for authentication
- Password validation (minimum 6 characters)
- Email validation
- Role-based access control

## Error Handling

All errors return a consistent format:
```json
{
  "success": false,
  "message": "Error message here"
}
```

## Development

The server uses `nodemon` for auto-reload during development. Any changes to the code will automatically restart the server.

