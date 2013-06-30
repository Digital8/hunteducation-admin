Entity = require './entity.coffee'

module.exports = class Set extends Entity
  
  constructor: (args = {}) ->
    
    super
    
    @key ?= 'id'
    
    @entities ?= {}
  
  new: (args = {}) ->
    
    return new @type args
  
  create: (args = {}) ->
    
    instance = new @type args
    
    id = instance[@key].toString()
    
    @entities[id] = instance
    
    return instance
  
  ensure: (instance) ->
    
    id = instance[@key].toString()
    
    unless @entities[id]?
      @entities[id] = instance
      @emit 'add', instance