import mongoose, { Document, Schema } from 'mongoose';

export interface IHeroSectionNumbers extends Document {
  propertiesListed: string;
  happyClients: string;
  daysToClose: string;
  createdAt: Date;
  updatedAt: Date;
}

const HeroSectionNumbersSchema: Schema = new Schema({
  propertiesListed: {
    type: String,
    required: [true, 'Properties listed number is required'],
    trim: true,
    maxlength: [20, 'Properties listed cannot exceed 20 characters']
  },
  happyClients: {
    type: String,
    required: [true, 'Happy clients number is required'],
    trim: true,
    maxlength: [20, 'Happy clients cannot exceed 20 characters']
  },
  daysToClose: {
    type: String,
    required: [true, 'Days to close number is required'],
    trim: true,
    maxlength: [20, 'Days to close cannot exceed 20 characters']
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Ensure only one document exists (singleton pattern)
HeroSectionNumbersSchema.pre('save', async function(next) {
  // If this is a new document and there's already one document, prevent creation
  if (this.isNew) {
    const existingDoc = await mongoose.model('HeroSectionNumbers').findOne({});
    if (existingDoc) {
      const error = new Error('Hero section numbers already exist. Use update instead.');
      return next(error);
    }
  }
  next();
});

export default mongoose.model<IHeroSectionNumbers>('HeroSectionNumbers', HeroSectionNumbersSchema);
