mongoose = require 'mongoose'

module.exports = mongoose.model 'Enrolment', new mongoose.Schema
  title: String
  'first-name': String
  'last-name': String
  email: String
  total_due: Number
  total_paid: Number
  paid_at: Date
  paid: Boolean
  customer_id: String
,
  id: false