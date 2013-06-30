socket = io.connect()

Set = require '../lib/set.coffee'

enrolments = new Set

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
  
  socket.emit 'get', 'enrolments', (error, enrolments) ->
    
    for key, enrolment of enrolments
      
      row = $ '<tr>'
      row.appendTo body
      
      for field in fields
        cell = $ '<td>'
        cell.text enrolment[field.key]
        cell.appendTo row