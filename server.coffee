fs = require 'fs'

async = require 'async'
express = require 'express'
mongoose = require 'mongoose'
optimist = require 'optimist'
uuid = require 'node-uuid'

config = require './config.coffee'

argv = optimist
  .usage("hunteducation-admin")
  .options(
    r:
      alias: 'root'
      description: 'root data directory'
  ).argv

console.log 'argv', argv

if argv.mongo?
  config.mongo = argv.mongo

root = argv.root or config.root

app = express()

app.set 'view engine', 'jade'
app.set 'views', "#{__dirname}/views"

app.use express.static "#{__dirname}/public"

app.use (require './server/browserify')
  entry: './client/entry.coffee'

Set = require './lib/set'

Enrolment = require './lib/enrolment'
Location = require './lib/location'
Intake = require './lib/intake'

db = {}
db.enrolments = new Set type: Enrolment, key: '_id'
db.locations = new Set type: Location, key: 'entity_id'
db.intakes = new Set type: Intake, key: 'entity_id'

mongoose.connect "mongodb://#{config.mongo.host}/#{config.mongo.db}"

mysql = (require 'mysql').createConnection config.mysql

mysql.query "SELECT * FROM timetable_location", (error, rows) ->
  return console.log 'error', error if error?
  for row in rows
    db.locations.create row

mysql.query "SELECT * FROM timetable_intake", (error, rows) ->
  return console.log 'error', error if error?
  for row in rows
    db.intakes.create row

models =
  Enrolment: require './lib/mongoose/enrolment'

fetchEnrolments = (callback) ->
  
  models.Enrolment
    .where('intake_id').ne(null)
    .where('uuid').ne(null)
    .exec (error, enrolments) ->
      async.map enrolments, (enrolment, callback) ->
        sql = "SELECT * FROM sales_flat_order WHERE customer_email = ?"
        mysql.query sql, [enrolment.email], (error, results) ->
          return callback error if error?
          return callback null unless results.length
          enrolment.order = results[0]
          enrolment.total_due = parseFloat enrolment.order.total_due
          enrolment.total_paid = parseFloat enrolment.order.total_paid
          enrolment.paid_at = enrolment.order.updated_at
          enrolment.paid = enrolment.total_due is 0
          callback null
      , (error) ->
        callback error, enrolments

fetchEnrolments (error, enrolments) ->
  
  for _enrolment in enrolments
    
    instance = db.enrolments.create _enrolment

setInterval ->
  
  fetchEnrolments (error, enrolments) ->
    
    for _enrolment in enrolments
      
      instance = db.enrolments.new _enrolment
      
      db.enrolments.ensure instance
  
, 3333

app.get '/', (req, res, next) ->
  
  res.render 'index'

# app.get '/files', (req, res, next) ->

#   fs.readdir root, (error, files) ->

#     return next error if error?

#     res.send files

server = app.listen 8080

io = (require 'socket.io').listen server, 'log level': 1

io.sockets.on 'connection', (socket) ->
  
  socket.on 'get', (key, callback) ->
    
    callback null, db[key]?.entities
  
  socket.on 'files', (enrolment, callback) ->
    
    console.log enrolment
    
    emailHash = uuid.v5 ns: '1bf34ef3-a7f8-4dec-aee2-eef4d9b89ccb', data: enrolment.email
    
    console.log 'listing files...', "#{root}/#{emailHash}/#{enrolment.uuid}"
    
    fs.readdir "#{root}/#{emailHash}/#{enrolment.uuid}", (error, paths) ->
      
      return callback error if error?
      
      files = {}
      
      for path in paths when path not in ['userdetails.txt']
        file =
          id: uuid()
          path: path
          src: "http://54.252.174.152/uploads/#{emailHash}/#{enrolment.uuid}/#{path}"
        files[file.id] = file
      
      callback null, files
  
db.enrolments.on 'add', (enrolment) ->
  console.log 'broadcasting enrolment'
  io.sockets.emit 'add', enrolment