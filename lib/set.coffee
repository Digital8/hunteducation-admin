Entity = require './entity.coffee'

module.exports = class Set extends Entity
  
  constructor: (args = {}) ->
    
    super
    
    @key ?= 'id'
    
    @entities ?= {}
  
  new: (args = {}) ->
    
    instance = new @type args
    
    id = instance[@key]
    
    @entities[id] = instance