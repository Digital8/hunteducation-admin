socket = io.connect()

Set = require '../lib/set.coffee'

db = {}

db.enrolments = new Set

$ ->
  
  dom = document.body
  
  table = $ '<table class="table table-striped">'
  table.appendTo dom
  
  fields = [
    {key: 'title'}
    {key: 'first-name'}
    {key: 'last-name'}
  ]
  
  header = $ '<thead>'
  header.appendTo table
  
  headerRow = $ '<tr>'
  headerRow.appendTo header
  
  for field in fields
    headerCell = $ '<th>'
    headerCell.text field.key
    headerCell.appendTo headerRow
  
  body = $ '<tbody>'
  body.appendTo table
  
  update = ->
    
    body.empty()
    
    for key, enrolment of db.enrolments.entities
      
      row = $ '<tr>'
      row.appendTo body
      
      for field in fields
        cell = $ '<td>'
        cell.text enrolment[field.key]
        cell.appendTo row
  
  socket.emit 'get', 'enrolments', (error, enrolments) ->
    
    db.enrolments.entities = enrolments
    
    update()
  
  socket.on 'add', (enrolment) ->
    
    enrolments.entities[enrolment.id] = enrolment
    
    update()