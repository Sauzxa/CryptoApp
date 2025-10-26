import mongoose, { Document, Schema } from 'mongoose';
import { v4 as uuidv4 } from 'uuid';

export interface IApartmentType extends Document {
  id: string;
  name: string;
}

const ApartmentTypeSchema: Schema = new Schema({
  id: {
    type: String,
    default: () => uuidv4(),
    required: true,
    unique: true
  },
  name: {
    type: String,
    required: [true, 'Apartment type name is required'],
    trim: true,
    maxlength: [50, 'Apartment type name cannot exceed 50 characters'],
    validate: {
      validator: function(value: string) {
        return value.trim().length > 0;
      },
      message: 'Apartment type name cannot be empty'
    }
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Create indexes for better performance
ApartmentTypeSchema.index({ name: 1 });

export default mongoose.model<IApartmentType>('ApartmentType', ApartmentTypeSchema);
