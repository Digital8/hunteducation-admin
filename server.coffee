fs = require 'fs'

express = require 'express'
mongoose = require 'mongoose'
optimist = require 'optimist'

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

db = {}
db.enrolments = new Set type: Enrolment

mongoose.connect "mongodb://#{config.mongo.host}/#{config.mongo.db}"

models =
  Enrolment: require './lib/mongoose/enrolment'

models.Enrolment.find (error, enrolments) ->
  
  for _enrolment in enrolments
    
    db.enrolments.new _enrolment

# fs.watch root, ->
#   console.log arguments

app.get '/', (req, res, next) ->
  
  res.render 'index'

# app.get '/files', (req, res, next) ->
  
#   fs.readdir root, (error, files) ->
    
#     return next error if error?
    
#     res.send files

server = app.listen 8080

io = (require 'socket.io').listen server

io.sockets.on 'connection', (socket) ->
  
  socket.on 'get', (key, callback) ->
    
    callback null, db[key]?.entities