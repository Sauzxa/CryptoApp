import mongoose, { Document, Schema } from 'mongoose';
import { v4 as uuidv4 } from 'uuid';

// Apartment Type interface
export interface IApartmentType {
  id: string;
  name: string; // e.g., "F2", "F3", "Duplex"
}

// Apartment interface
export interface IApartment {
  id: string;
  imageUrl: string;
  description: string;
  types: IApartmentType[];
}

// Region interface
export interface IRegion extends Document {
  id: string;
  name: string;
  apartments: IApartment[];
}

// Apartment Type Schema
const ApartmentTypeSchema = new Schema({
  id: {
    type: String,
    default: () => uuidv4(),
    required: true
  },
  name: {
    type: String,
    required: [true, 'Type name is required'],
    trim: true,
    maxlength: [50, 'Type name cannot exceed 50 characters']
  }
}, { _id: false });

// Apartment Schema
const ApartmentSchema = new Schema({
  id: {
    type: String,
    default: () => uuidv4(),
    required: true
  },
  imageUrl: {
    type: String,
    required: [true, 'Image URL is required'],
    trim: true,
    validate: {
      validator: function(url: string) {
        // Basic URL validation for Cloudinary URLs
        return /^https?:\/\/.+\.(jpg|jpeg|png|gif|webp)$/i.test(url) || 
               /^https:\/\/res\.cloudinary\.com\//.test(url);
      },
      message: 'Please provide a valid image URL'
    }
  },
  description: {
    type: String,
    required: [true, 'Description is required'],
    trim: true,
    maxlength: [500, 'Description cannot exceed 500 characters']
  },
  types: [ApartmentTypeSchema]
}, { _id: false });

// Region Schema
const RegionSchema: Schema = new Schema({
  id: {
    type: String,
    default: () => uuidv4(),
    required: true,
    unique: true
  },
  name: {
    type: String,
    required: [true, 'Region name is required'],
    trim: true,
    maxlength: [100, 'Region name cannot exceed 100 characters'],
    validate: {
      validator: function(value: string) {
        return value.trim().length > 0;
      },
      message: 'Region name cannot be empty'
    }
  },
  apartments: [ApartmentSchema]
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Create indexes for better performance  
// Note: id index is already created by unique: true in schema definition
RegionSchema.index({ name: 1 });

export default mongoose.model<IRegion>('Region', RegionSchema);
