import mongoose, { Document, Schema } from 'mongoose';

export interface IDashboardDiv extends Document {
  id: 1 | 2 | 3; // Fixed values only
  photoUrl: string;
  price: number;
  apartment: string;
}

const DashboardDivSchema: Schema = new Schema({
  id: {
    type: Number,
    required: [true, 'ID is required'],
    enum: [1, 2, 3],
    unique: true,
    validate: {
      validator: function(value: number) {
        return [1, 2, 3].includes(value);
      },
      message: 'ID must be 1, 2, or 3'
    }
  },
  photoUrl: {
    type: String,
    required: [true, 'Photo URL is required'],
    trim: true,
    validate: {
      validator: function(url: string) {
        // URL validation for various image providers
        return /^https?:\/\/.+\.(jpg|jpeg|png|gif|webp)(\?.*)?$/i.test(url) || 
               /^https:\/\/res\.cloudinary\.com\//.test(url) ||
               /^https:\/\/images\.unsplash\.com\//.test(url);
      },
      message: 'Please provide a valid image URL'
    }
  },
  price: {
    type: Number,
    required: [true, 'Price is required'],
    min: [0, 'Price must be a positive number'],
    validate: {
      validator: function(value: number) {
        return value >= 0 && Number.isFinite(value);
      },
      message: 'Price must be a valid positive number'
    }
  },
  apartment: {
    type: String,
    required: [true, 'Apartment type is required'],
    trim: true,
    maxlength: [100, 'Apartment type cannot exceed 100 characters'],
    validate: {
      validator: function(value: string) {
        return value.trim().length > 0;
      },
      message: 'Apartment type cannot be empty'
    }
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Index is already created by unique: true in schema definition

export default mongoose.model<IDashboardDiv>('DashboardDiv', DashboardDivSchema);
