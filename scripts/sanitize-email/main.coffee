fs   = require 'fs'
path = require 'path'

_ = require 'underscore'

Bongo   = require 'bongo'

KONFIG = require 'koding-config-manager'
mongo  = "mongodb://#{KONFIG.mongo}"

modelPath = '../../workers/social/lib/social/models'
rekuire   = (p) -> require path.join modelPath, p

JUser = rekuire 'user'

koding = new Bongo
  root   : __dirname
  mongo  : mongo
  models : modelPath

emailsanitize = rekuire 'user/emailsanitize'

sanitizeEmail = (user, callback) ->

  { _id, email, sanitizedEmail } =  user

  unless sanitizedEmail
    sanitizedEmail = emailsanitize email, { excludeDots: yes, excludePlus: yes }
    user.sanitizedEmail = sanitizedEmail

  query   = { _id }
  update  = { $set: { sanitizedEmail } }
  options = {}

  JUser.update query, update, options, callback


abuseMap = {}

handleAbuse = (user) ->

  { _id, username, email, sanitizedEmail } = user

  entry = abuseMap[sanitizedEmail] ?=
    count     : 0
    email     : sanitizedEmail
    usernames : []

  entry.usernames.push username
  entry.count++

  console.warn "abuse: #{_id} #{username} #{email} #{sanitizedEmail}"


handleError = (user, err) ->

  switch err.code
    when 11000, 11001 # duplicate key error
      handleAbuse user
    else
      console.error "error: #{JSON.stringify err}"


getFailover = (user) ->

  { email, sanitizedEmail } = user

  [local, host] = email.split '@'
  [sanitizedLocal] = sanitizedEmail.split '@'

  # This failover value is generated to avoid null values in sanitized
  # email field
  return "#{sanitizedLocal}+#{local}@#{host}"


printReport = ->

  list = (Object.keys abuseMap).map (key) -> abuseMap[key]
  list = (_.sortBy list, 'count').reverse()

  report = ''
  for entry in list
    { email, count, usernames } = entry
    report += "#{count} #{email}\n"
    report += usernames.join '\n'
    report += '\n\n'

  fs.writeFileSync 'ABUSE_REPORT', report


koding.once 'dbClientReady', ->

  fields = { _id: 1, username: 1, email: 1, sanitizedEmail: 1 }

  JUser.someData {}, fields, {}, (err, cursor) ->

    return console.error err  if err

    migrate = (user, fallback, callback) ->

      { username, email, sanitizedEmail } = user

      sanitizeEmail user, (err) ->
        return callback()  unless err

        if fallback
          console.error "migrate: #{email} fallback has failed"
          console.error JSON.stringify err
          return callback()

        handleError user, err
        user.sanitizedEmail = getFailover user
        migrate user, yes, callback

    iterate = do (i = 0) ->

      next = -> process.nextTick iterate

      ->

        cursor.nextObject (err, user) ->

          if err
            console.error 'error: cursor next object fetcher failed'
            console.error JSON.stringify err
            return process.exit 1

          unless user
            printReport()
            return process.exit 0

          if user.sanitizedEmail
          then next()
          else migrate user, no, next

    iterate()
