{EventEmitter} = require 'events'
uuid = require 'node-uuid'

module.exports = class Entity extends EventEmitter
  
  constructor: (args = {}) ->
    
    super
    
    @[key] ?= value for key, value of args
    
    @id ?= args.id or uuid()