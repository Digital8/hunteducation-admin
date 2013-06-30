socket = io.connect()

Set = require '../lib/set.coffee'

db = {}

db.enrolments = new Set

$ ->
  
  dom = document.body
  
  table = $ '<table class="table table-striped">'
  table.appendTo dom
  
  fields = []
  
  date = (field) ->
    for key in ['day', 'month', 'year']
      fields.push key: "#{field}-#{key}"
  
  fields.push {key: '_id'}
  fields.push {key: 'title'}
  fields.push {key: 'first-name'}
  fields.push {key: 'last-name'}
  fields.push {key: 'dob-day'}
  fields.push {key: 'dob-month'}
  fields.push {key: 'dob-year'}
  fields.push {key: 'gender'}
  fields.push {key: 'health_cover'}
  fields.push {key: 'disability'}
  fields.push {key: 'agency'}
  fields.push {key: 'address'}
  fields.push {key: 'state'}
  fields.push {key: 'postcode'}
  fields.push {key: 'email'}
  fields.push {key: 'mobile'}
  fields.push {key: 'phone'}
  fields.push {key: 'birth-country'}
  fields.push {key: 'citizenship-country'}
  fields.push {key: 'passport'}
  fields.push {key: 'visa-485'}
  date 'visa-expiry'
  fields.push {key: 'current-visa-subclass'}
  
  for key in ['australia', 'overseas', 'ielts']
    date "#{key}-education-commenced"
    fields.push {key: "#{key}-education-course-name"}
    fields.push {key: "#{key}-education-institute"}
  
  fields.push {key: 'qualification-assessment'}
  fields.push {key: 'assessing-body'}
  date 'assessment'
  fields.push {key: 'subjects-remaining'}
  fields.push {key: 'referral-where'}
  fields.push {key: 'radio-station'}
  fields.push {key: 'print-media'}
  fields.push {key: 'friend-name'}
  fields.push {key: 'friend-email'}
  fields.push {key: 'friend-phone'}
  fields.push {key: 'other-referral'}
  fields.push {key: 'hideit'}
  
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
    
    db.enrolments.entities[enrolment._id] = enrolment
    
    update()