Entity = require './entity.coffee'

module.exports = class Order extends Entity
  
  constructor: (args = {}) ->
    
    super