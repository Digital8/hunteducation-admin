Entity = require './entity.coffee'

module.exports = class OrderItem extends Entity
  
  constructor: (args = {}) ->
    
    super
    
    {unserialize} = require 'php-unserialize'
    @enrolment_id = (unserialize @product_options)?.options?[0]?.value