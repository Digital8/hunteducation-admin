_s = require 'underscore.string'

socket = io.connect()

Set = require '../lib/set.coffee'

db = {}

db.enrolments = new Set

$ ->
  
  dom = document.body
  
  table = $ '<table class="table table-striped">'
  table.appendTo dom
  
  fields = {}
  fieldsets = {}
  
  # date = (field) ->
  #   for key in ['day', 'month', 'year']
  #     fields.push key: "#{field}-#{key}"
  
  fieldset = (key, callback, args = {}) ->
    
    args.display ?= yes
    
    set = {}
    
    set.fields = {}
    
    callback (key) ->
      map = key: key
      for argKey, argValue of args
        map[argKey] = argValue
      set.fields[key] = map
      fields[key] = map
    
    fieldsets[key] = set
    
    return set
  
  field = (key, args = {}) ->
    fieldset key, (field) ->
      field key
    , args
  
  field '_id', display: no
  
  field 'title'
  
  fieldset 'name', (field) ->
    field 'first-name'
    field 'last-name'
  
  fieldset 'dob', (field) ->
    field 'dob-day'
    field 'dob-month'
    field 'dob-year'
  , display: no
  
  field 'gender'
  
  field 'health_cover'
  
  field 'disability'
  
  field 'agency'
  
  fieldset 'address', (field) ->
    field 'address'
    field 'state'
    field 'postcode'
  , display: no
  
  fieldset 'contact', (field) ->
    field 'email'
    field 'mobile'
    field 'phone'
  , display: no
  
  field 'birth-country'
  
  field 'citizenship-country'
  
  field 'passport'
  
  fieldset 'visa', (field) ->
    field 'visa-485'
    field 'visa-expiry-day'
    field 'visa-expiry-month'
    field 'visa-expiry-year'
    field 'current-visa-subclass'
  , display: no
  
  for key in ['australia', 'overseas', 'ielts']
    fieldset "#{key}-education", (field) ->
      field "#{key}-education-commenced-day"
      field "#{key}-education-commenced-month"
      field "#{key}-education-commenced-year"
      
      field "#{key}-education-course-name"
      field "#{key}-education-institute"
    , display: no
  
  fieldset 'assessment', (field) ->
    field 'qualification-assessment'
    field 'assessing-body'
    field 'assessment-day'
    field 'assessment-month'
    field 'assessment-year'
    field 'subjects-remaining'
  , display: no
  
  fieldset 'referral', (field) ->
    field 'referral-where'
    field 'radio-station'
    field 'print-media'
    field 'friend-name'
    field 'friend-email'
    field 'friend-phone'
    field 'other-referral'
    field 'hideit'
  , display: no
  
  header = $ '<thead>'
  header.appendTo table
  
  headerRow = $ '<tr>'
  headerRow.appendTo header
  
  for fieldKey, field of fields when field.display
    headerCell = $ '<th>'
    headerCell.text _s.humanize field.key
    headerCell.appendTo headerRow
  
  body = $ '<tbody>'
  body.appendTo table
  
  update = ->
    
    body.empty()
    
    for key, enrolment of db.enrolments.entities
      
      row = $ '<tr>'
      row.appendTo body
      
      for fieldKey, field of fields when field.display
        cell = $ '<td>'
        cell.text enrolment[field.key]
        cell.appendTo row
  
  socket.emit 'get', 'enrolments', (error, enrolments) ->
    
    db.enrolments.entities = enrolments
    
    update()
  
  socket.on 'add', (enrolment) ->
    
    db.enrolments.entities[enrolment._id] = enrolment
    
    update()