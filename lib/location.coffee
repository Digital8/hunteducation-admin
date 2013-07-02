Entity = require './entity.coffee'

module.exports = class Location extends Entity
  
  constructor: (args = {}) ->
    
    super