browserify = require 'browserify'
coffeeify = require 'caching-coffeeify'
concat = require 'concat-stream'

module.exports = (args = {}) ->
  
  args.ignore ?= []
  
  b = browserify()
  
  for key in args.ignore
    
    b.ignore key
  
  b.transform coffeeify
  
  b.add args.entry
  
  (req, res, next) ->
    
    return next() unless req.url is '/bundle.js'
    
    b.bundle().pipe concat (data) ->
      res.send data