mongoose = require 'mongoose'

module.exports = mongoose.model 'Enrolment', new mongoose.Schema
  title: String
  'first-name': String
  'last-name': String
  # created_at: { type: Date, default: Date.now }
,
  id: false