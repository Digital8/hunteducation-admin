_ = require 'underscore'
_s = require 'underscore.string'
async = require 'async'
moment = require 'moment'

socket = io.connect()

Set = require '../lib/set.coffee'

window.db = db = {}

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
    # set.key = key # wtf
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
  
  enrolmentsList = $ '<div>'
  enrolmentsList.appendTo dom
  
  config = $ '<a href="#">config</a>'
  config.appendTo enrolmentsList
  config.click (event) ->
    event.preventDefault()
    ($ '#config').toggle()
  
  do ->
    table = $ '<table id="config" class="table table-striped table-hover table-condensed">'
    table.hide()
    table.appendTo enrolmentsList
    
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
  table.appendTo enrolmentsList
  
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
          event.preventDefault()
          inspectEnrolment enrolment
    
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
  
  # intakes / locations
  async.map ['intakes', 'locations'], (key, callback) ->
    socket.emit 'get', key, (error, records) ->
      return callback error if error?
      db[key].entities = records
      callback null
  , (error) ->
    
    console.log error if error?
    
    for key, intake of db.intakes.entities
      intake.location = _.find db.locations.entities, (location) ->
        location.entity_id is intake.location_id
    
    syncEnrolments()
  
  inspectEnrolment = (enrolment) ->
    
    enrolmentsList.hide()
    
    enrolmentView = $ '<div>'
    enrolmentView.appendTo dom
    
    back = $ '<a href="#">back</a>'
    back.appendTo enrolmentView
    back.click (event) ->
      enrolmentView.remove()
      enrolmentsList.show()
    
    tabs = [
      {key: 'details', label: 'Personal Details', active: yes}
      {key: 'course', label: 'Intake & Location'}
      {key: 'documents', label: 'Documents'}
      {key: 'payment', label: 'Payment'}
    ]
    
    nav = $ """<ul class="nav nav-tabs">"""
    nav.appendTo enrolmentView
    
    for tab in tabs then do (tab) ->
      li = $ """
      <li data-tabkey="#{tab.key}">
        <a href="##{tab.key}">
        #{tab.label}
        <span class="badge"></span>
        </a>
      </li>
      """
      li.addClass 'active' if tab.active
      li.appendTo nav
      
      do (li) ->
        
        li.click ->
          nav.find('li').removeClass 'active'
          li.addClass 'active'
          ($ '[data-tab]').hide()
          ($ "[data-tab=#{tab.key}]").show()
    
    form = $ '<form class="form-horizontal" data-tab="details">'
    form.appendTo enrolmentView
    
    row = $ """
    <div class="row-fluid">
    """
    row.appendTo form
    
    left = $ """<div class="span6">"""
    left.appendTo row
    right = $ """<div class="span6">"""
    right.appendTo row
    
    formify = (parent, fieldset, key) ->
      
      fieldsetKey = fieldset.key
      
      group = $ """
      <fieldset>
        <legend>#{_s.humanize key}</legend>
      </fieldset>
      """
      group.find('legend').css 'line-height': '20px', margin: 0
      group.appendTo parent
      
      do (group) ->
        
        for fieldKey, field of fieldset.fields
          control = $ """
            <div class="control-group">
              <label class="control-label">#{_s.humanize fieldKey}</label>
              <div class="controls">
                <input type="text" placeholder="#{_s.humanize fieldKey}" value="#{enrolment[fieldKey]}">
              </div>
            </div>
          """
          control.css 'margin-top': 10, 'margin-bottom': 10
          control.appendTo group
    
    for pair, index in _.pairs fieldsets
      
      [key, fieldset] = pair
      
      continue if key in ['intake', '_id']
      
      if index % 2
        
        formify left, fieldset, key
      
      else
        
        formify right, fieldset, key
    
    # intake
    intakeView = $ '<form class="form-horizontal" data-tab="course">'
    intakeView.appendTo enrolmentView
    
    # intake select
    control = $ """
      <div class="control-group">
        <label class="control-label">Intake</label>
        <div class="controls">
          <select></select>
        </div>
      </div>
    """
    control.appendTo intakeView
    
    select = control.find 'select'
    select.append $ '<option value="">'
    
    for key, intake of db.intakes.entities
      option = $ "<option>"
      option.attr value: intake.entity_id
      option.text intake.name
      option.appendTo select
    
    select.val enrolment.intake.entity_id
    
    # intake
    if enrolment.intake?
      
      table = $ '<table class="table table-striped table-hover table-condensed">'
      table.appendTo intakeView
      
      tbody = $ '<tbody>'
      tbody.appendTo table
      
      for key in ['name', 'date', 'enrolled']
        
        value = enrolment.intake[key]
        
        if key is 'date'
          value = (moment value).format 'LLL'
        
        row = $ """
        <tr>
          <td>#{_s.humanize key}</td>
          <td>#{value}</td>
        </tr>
        """
        row.appendTo tbody
      
      # location
      if enrolment.intake?.location?
        
        row = $ """
        <tr>
          <td>Location</td>
        </tr>
        """
        row.appendTo tbody
        
        parent = $ '<td>'
        parent.appendTo row
        
        table = $ '<table class="table table-striped table-hover table-condensed">'
        table.appendTo parent
        
        tbody = $ '<tbody>'
        tbody.appendTo table
        
        for key in ['name', 'address', 'suburb', 'state']
          
          value = enrolment.intake.location[key]
          
          row = $ """
          <tr>
            <td>#{_s.humanize key}</td>
            <td>#{value}</td>
          </tr>
          """
          row.appendTo tbody
    
    # documents
    documentsView = $ '<ul class="thumbnails" data-tab="documents" style="display: none;">'
    documentsView.appendTo enrolmentView
    
    socket.emit 'files', enrolment, (error, files) ->
      
      if error?
        ($ '[data-tabkey=documents]').hide()
        console.log error
        return
      
      ($ '[data-tabkey=documents] .badge').text _.size files
      
      for key, file of files
        thumb = $ """
        <li class="span4">
          <div class="thumbnail">
            <a href="#{file.src}" target="_blank">
              <img src="#{file.src}" alt="" />
            </a>
            <p>#{file.path}</p>
          </div>
        </li>
        """
        thumb.appendTo documentsView
    
    # payment
    paymentView = $ """
    <table class="table table-striped table-hover table-condensed" data-tab="payment">
      <thead>
        <tr>
          <th>Date</th>
          <th>Amount</th>
        </tr>
      </thead>
    </table>
    """
    paymentView.appendTo enrolmentView
    badge = nav.find 'li[data-tabkey=payment] .badge'
    badge.removeClass 'badge badge-info'
    badge.addClass 'label label-important'
    badge.text 'unpaid'