fs = require 'fs'

express = require 'express'

config = require './config.coffee'

app = express()

express.get '/', (req, res, next) ->
  
  res.send 200

express.get '/files'
  
  fs.readdir config.root, (error, files) ->
    
    return next error if error?
    
    res.send files

server = app.listen 8080