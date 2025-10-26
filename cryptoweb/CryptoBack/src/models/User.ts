import mongoose, { Document, Schema } from 'mongoose';

export interface IUser extends Document {
  name: string;
  number: string;
  message?: string;
  typeAppartement: string;
  reservationDate: Date;
  status: 'Pending' | 'Done';
  id: string;
}

const UserSchema: Schema = new Schema({
  name: {
    type: String,
    required: [true, 'Name is required'],
    trim: true,
    maxlength: [100, 'Name cannot exceed 100 characters']
  },
  number: {
    type: String,
    required: [true, 'Phone number is required'],
    trim: true,
    maxlength: [20, 'Phone number cannot exceed 20 characters']
  },
  message: {
    type: String,
    required: false,
    trim: true,
    maxlength: [1000, 'Message cannot exceed 1000 characters']
  },
  typeAppartement: {
    type: String,
    required: [true, 'Apartment type is required'],
    trim: true,
    maxlength: [50, 'Apartment type cannot exceed 50 characters']
  },
  reservationDate: {
    type: Date,
    required: [true, 'Reservation date is required']
  },
  status: {
    type: String,
    enum: ['Pending', 'Done'],
    default: 'Pending'
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Create index for better query performance
UserSchema.index({ status: 1 });
UserSchema.index({ reservationDate: -1 });

export default mongoose.model<IUser>('User', UserSchema);
