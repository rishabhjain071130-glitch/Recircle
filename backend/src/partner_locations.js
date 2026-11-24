const express = require('express');
const mongoose = require('mongoose');
const { z } = require('zod');
const { auth } = require('./middleware/auth');

const partnerLocationSchema = new mongoose.Schema({
  partner: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true, index: true },
  location: {
    type: { type: String, enum: ['Point'], required: true },
    coordinates: {
      type: [Number],
      required: true,
      validate: {
        validator: (value) => Array.isArray(value) && value.length === 2
          && value[0] >= -180 && value[0] <= 180
          && value[1] >= -90 && value[1] <= 90,
        message: 'Location coordinates are invalid',
      },
    },
  },
  updatedAt: { type: Date, default: Date.now },
}, { timestamps: true });

partnerLocationSchema.index({ location: '2dsphere' });

const PartnerLocation = mongoose.models.PartnerLocation
  || mongoose.model('PartnerLocation', partnerLocationSchema);

const locationSchema = z.object({
  latitude: z.number().min(-90).max(90),
  longitude: z.number().min(-180).max(180),
}).strict();

const nearbyQuerySchema = z.object({
  latitude: z.coerce.number().min(-90).max(90),
  longitude: z.coerce.number().min(-180).max(180),
  radiusKm: z.coerce.number().min(1).max(50).default(10),
}).strict();

function validate(schema, value) {
  const parsed = schema.safeParse(value);
  if (!parsed.success) {
    const error = new Error('Invalid location data');
    error.status = 400;
    throw error;
  }
  return parsed.data;
}

module.exports = ({ models, config }) => {
  const router = express.Router();

  router.put('/partners/me/location', auth(config, 'partner'), async (req, res, next) => {
    try {
      const body = validate(locationSchema, req.body);
      if (req.user.partnerStatus !== 'approved') {
        return res.status(403).json({
          success: false,
          error: { message: 'Only approved partners can publish a collection location' },
        });
      }

      const location = await PartnerLocation.findOneAndUpdate(
        { partner: req.user.id },
        {
          partner: req.user.id,
          location: {
            type: 'Point',
            coordinates: [body.longitude, body.latitude],
          },
          updatedAt: new Date(),
        },
        { upsert: true, new: true, setDefaultsOnInsert: true },
      ).lean();

      return res.json({
        success: true,
        data: {
          partnerId: req.user.id,
          latitude: location.location.coordinates[1],
          longitude: location.location.coordinates[0],
          updatedAt: location.updatedAt,
        },
      });
    } catch (error) {
      return next(error);
    }
  });

  router.delete('/partners/me/location', auth(config, 'partner'), async (req, res, next) => {
    try {
      await PartnerLocation.deleteOne({ partner: req.user.id });
      return res.json({ success: true, data: { removed: true } });
    } catch (error) {
      return next(error);
    }
  });

  router.get('/partners/nearby', auth(config, 'customer'), async (req, res, next) => {
    try {
      const query = validate(nearbyQuerySchema, req.query);
      const partners = await PartnerLocation.aggregate([
        {
          $geoNear: {
            near: {
              type: 'Point',
              coordinates: [query.longitude, query.latitude],
            },
            key: 'location',
            distanceField: 'distanceMeters',
            maxDistance: query.radiusKm * 1000,
            spherical: true,
            query: { },
          },
        },
        {
          $lookup: {
            from: models.User.collection.name,
            localField: 'partner',
            foreignField: '_id',
            as: 'partner',
          },
        },
        { $unwind: '$partner' },
        {
          $match: {
            'partner.role': 'partner',
            'partner.active': true,
            'partner.partnerStatus': 'approved',
            'partner.partnerAvailable': true,
          },
        },
        {
          $project: {
            _id: 0,
            partnerId: '$partner._id',
            name: '$partner.name',
            phone: '$partner.phone',
            address: '$partner.address',
            city: '$partner.city',
            pinCode: '$partner.pinCode',
            serviceArea: '$partner.serviceArea',
            available: '$partner.partnerAvailable',
            latitude: { $arrayElemAt: ['$location.coordinates', 1] },
            longitude: { $arrayElemAt: ['$location.coordinates', 0] },
            distanceMeters: 1,
            updatedAt: 1,
          },
        },
        { $sort: { distanceMeters: 1 } },
        { $limit: 50 },
      ]);

      return res.json({
        success: true,
        data: partners.map((partner) => ({
          ...partner,
          partnerId: partner.partnerId.toString(),
          distanceKm: Number((partner.distanceMeters / 1000).toFixed(1)),
        })),
      });
    } catch (error) {
      return next(error);
    }
  });

  return router;
};

module.exports.PartnerLocation = PartnerLocation;
