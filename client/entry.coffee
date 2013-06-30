_ = require 'underscore'
_s = require 'underscore.string'

socket = io.connect()

Set = require '../lib/set.coffee'

db = {}

db.enrolments = new Set

$ ->
  
  dom = document.body
  
  fields = {}
  fieldsets = {}
  
  update = null
  
  fieldset = (key, callback, args = {}) ->
    
    args.display ?= yes
    
    set = args
    
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
  
  fieldset 'names', (field) ->
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
    # field 'hideit'
  , display: no
  
  config = $ '<a href="#">config</a>'
  config.appendTo dom
  config.click (event) ->
    event.preventDefault()
    ($ '#config').toggle()
  
  do ->
    table = $ '<table id="config" class="table table-striped">'
    table.hide()
    table.appendTo dom
    
    header = $ '<thead>'
    header.appendTo table
    
    headerRow = $ '<tr>'
    headerRow.appendTo header
    
    # for key, fieldset of fieldsets
    #   headerCell = $ '<th>'
    #   headerCell.text _s.humanize key
    #   headerCell.appendTo headerRow
    
    headerRow.append $ '<th>show</th>'
    headerRow.append $ '<th>key</th>'
    headerRow.append $ '<th>fields</th>'
    
    body = $ '<tbody>'
    body.appendTo table
    
    for key, fieldset of fieldsets then do (key, fieldset) ->
      
      row = $ '<tr>'
      row.appendTo body
      
      showCell = $ """<td><input type="checkbox" /></td>"""
      showCell.find('input').prop 'checked', fieldset.display
      
      showCell.find('input').change ->
        display = showCell.find('input').prop 'checked'
        fieldset = fieldsets[key]
        fieldset.display = display
        for fieldKey, field of fieldset.fields
          field.display = display
        update()
      
      showCell.appendTo row
      row.append $ """<td>#{_s.humanize key}</td>"""
      keys = _.pluck (_.values fieldset.fields), 'key'
      keys = (_s.humanize k for k in keys)
      row.append $ """<td>#{keys.join ', '}</td>"""
    
    return
  
  table = $ '<table class="table table-striped">'
  table.appendTo dom
  
  header = $ '<thead>'
  header.appendTo table
  
  headerRow = $ '<tr>'
  headerRow.appendTo header
  
  body = $ '<tbody>'
  body.appendTo table
  
  update = ->
    
    headerRow.empty()
    
    for fieldKey, field of fields when field.display
      headerCell = $ '<th>'
      headerCell.text _s.humanize field.key
      headerCell.appendTo headerRow
    
    body.empty()
    
    for key, enrolment of db.enrolments.entities
      
      row = $ '<tr>'
      row.appendTo body
      
      for fieldKey, field of fields when field.display
        cell = $ '<td>'
        cell.text enrolment[field.key]
        cell.appendTo row
    
    return
  
  socket.emit 'get', 'enrolments', (error, enrolments) ->
    
    db.enrolments.entities = enrolments
    
    update()
  
  socket.on 'add', (enrolment) ->
    
    db.enrolments.entities[enrolment._id] = enrolment
    
    update()