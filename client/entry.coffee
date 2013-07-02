_ = require 'underscore'
_s = require 'underscore.string'
async = require 'async'

socket = io.connect()

Set = require '../lib/set.coffee'

db = {}

db.locations = new Set
db.intakes = new Set
db.enrolments = new Set

$ ->
  
  dom = document.body
  
  fields = {}
  fieldsets = {}
  filters = {}
  
  update = null
  
  fieldset = (key, callback, args = {}) ->
    
    args.display ?= yes
    
    set = args
    
    set.fields = {}
    
    callback (key, fieldArgs = {}) ->
      map = fieldArgs
      map.key = key
      map.stringify ?= (value) -> value
      # map.filter ?= null
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
  
  field '_id', label: 'ID'
  
  fieldset 'intake', (field) ->
    field 'intake',
      stringify: (intake) ->
        intake?.name
      filter:
        type: 'select'
        options: ->
          db.intakes.entities
        key: 'intake_id'
  
  field 'title'
  
  fieldset 'names', (field) ->
    field 'first-name'
    field 'last-name'
  
  fieldset 'dob', (field) ->
    field 'dob-day'
    field 'dob-month'
    field 'dob-year'
  
  field 'gender'
  
  field 'health_cover', display: no
  
  field 'disability', display: no
  
  field 'agency', display: no
  
  fieldset 'address', (field) ->
    field 'address'
    field 'state'
    field 'postcode'
  , display: no
  
  fieldset 'contact', (field) ->
    field 'email'
    field 'mobile'
    field 'phone'
  
  field 'birth-country', display: no
  
  field 'citizenship-country', display: no
  
  field 'passport', display: no
  
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
    table = $ '<table id="config" class="table table-striped table-hover table-condensed">'
    table.hide()
    table.appendTo dom
    
    header = $ '<thead>'
    header.appendTo table
    
    headerRow = $ '<tr>'
    headerRow.appendTo header
    
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
  
  table = $ '<table class="table table-striped table-hover table-condensed">'
  table.appendTo dom
  
  header = $ '<thead>'
  header.appendTo table
  
  headerRow = $ '<tr>'
  headerRow.appendTo header
  
  filterRow = $ '<tr>'
  filterRow.addClass 'info'
  filterRow.appendTo header
  
  body = $ '<tbody>'
  body.appendTo table
  
  update = ->
    
    hydrateEnrolments()
    
    # labels
    headerRow.empty()
    for fieldKey, field of fields when field.display
      headerCell = $ '<th>'
      headerCell.text if field.label?
        field.label
      else
        _s.humanize field.key
      headerCell.appendTo headerRow
    
    # filters
    filterRow.empty()
    for fieldKey, field of fields when field.display then do (fieldKey, field) ->
      headerCell = $ '<th>'
      if field.filter?
        if field.filter.type is 'select'
          select = $ '<select class="input-small">'
          select.appendTo headerCell
          select.append $ '<option value="">'
          for key, value of field.filter.options()
            option = $ '<option>'
            option.text value.name
            option.attr value: value.entity_id
            option.appendTo select
          select.val filters[field.filter.key]
          select.change (event) ->
            filters[field.filter.key] = select.val()
            update()
      headerCell.appendTo filterRow
    
    body.empty()
    
    enrolments = if _.size filters
      _.where db.enrolments.entities, filters
    else db.enrolments.entities
    
    for key, enrolment of enrolments then do (key, enrolment) ->
      
      row = $ '<tr>'
      row.appendTo body
      
      for fieldKey, field of fields when field.display
        cell = $ '<td>'
        cell.text field.stringify enrolment[field.key]
        cell.appendTo row
      
      do (row) ->
        
        row.click (event) ->
          
          if row.data 'expand'
            (row.data 'expand').remove()
            (row.data 'expand', null)
          else
            event.preventDefault()
            socket.emit 'files', enrolment, (error, files) ->
              
              return console.log error if error?
              
              table = $ '<table>'
              
              for key, file of files
                
                console.log file
                
                fileRow = $ '<tr>'
                fileRow.appendTo table
                
                thumbCell = $ '<td>'
                thumbCell.appendTo fileRow
                thumb = $ '<img>'
                thumb.attr src: file.src
                thumb.css 'max-width': 200, 'max-height': 200
                thumb.appendTo thumbCell
              
              wrapper = $ '<tr>'
              wrapper.append table
              
              row.after wrapper
              
              row.data 'expand', wrapper
    
    return
  
  hydrateEnrolments = ->
    
    for key, enrolment of db.enrolments.entities
      
      intake = _.find db.intakes.entities, (intake) ->
        (parseInt intake.entity_id) is (parseInt enrolment.intake_id)
      
      enrolment.intake = intake
  
  # start syncing the enrolments
  # pre - intakes/locations
  # post - fetched existing enrolments
  # post - listens for new enrolments
  syncEnrolments = ->
    
    socket.emit 'get', 'enrolments', (error, enrolments) ->
    
      db.enrolments.entities = enrolments
      
      update()
    
    socket.on 'add', (enrolment) ->
      
      db.enrolments.entities[enrolment._id] = enrolment
      
      update()
  
  # intakes
  
  socket.emit 'get', 'intakes', (error, intakes) ->
    
    db.intakes.entities = intakes
    
    syncEnrolments()