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

  router.patch('/partners/me/location', auth(config, 'partner'), async (req, res, next) => {
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
            businessName: '$partner.businessName',
            partnerType: '$partner.partnerType',
            acceptedCategories: '$partner.acceptedCategories',
            partnerStatus: '$partner.partnerStatus',
            phone: '$partner.phone',
            address: '$partner.address',
            city: '$partner.city',
            pinCode: '$partner.pinCode',
            serviceArea: '$partner.serviceArea',
            available: '$partner.partnerAvailable',
            registeredAt: '$partner.createdAt',
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

  router.get('/partners/:id', auth(config, 'customer'), async (req, res, next) => {
    try {
      if (!mongoose.isValidObjectId(req.params.id)) {
        return res.status(400).json({ success: false, error: { message: 'Invalid partner ID' } });
      }
      const partner = await models.User.findOne({
        _id: req.params.id, role: 'partner', active: true, partnerStatus: 'approved',
      }).select('name businessName partnerType acceptedCategories phone address city pinCode serviceArea partnerStatus partnerAvailable createdAt').lean();
      if (!partner) return res.status(404).json({ success: false, error: { message: 'Approved partner not found' } });
      const location = await PartnerLocation.findOne({ partner: partner._id }).select('location').lean();
      return res.json({
        success: true,
        data: {
          id: partner._id.toString(),
          name: partner.name,
          businessName: partner.businessName || '',
          partnerType: partner.partnerType || '',
          acceptedCategories: partner.acceptedCategories || [],
          phone: partner.phone,
          address: partner.address,
          city: partner.city,
          pinCode: partner.pinCode,
          serviceArea: partner.serviceArea,
          partnerStatus: partner.partnerStatus,
          available: partner.partnerAvailable,
          registeredAt: partner.createdAt,
          ...(location ? {
            latitude: location.location.coordinates[1],
            longitude: location.location.coordinates[0],
          } : {}),
        },
      });
    } catch (error) {
      return next(error);
    }
  });

  return router;
};

module.exports.PartnerLocation = PartnerLocation;
