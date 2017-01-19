
createUsers = (users) ->

  Bongo     = require 'bongo'

  { join: joinPath } = require 'path'

  KONFIG = require 'koding-config-manager'
  mongo  = "mongodb://#{KONFIG.mongo}"

  if process.env.MONGO_URL
    mongo = process.env.MONGO_URL

  modelPath = '../../workers/social/lib/social/models'
  rekuire   = (p) -> require joinPath modelPath, p

  koding = new Bongo
    root   : __dirname
    mongo  : mongo
    models : modelPath

  console.log "Trying to connect #{mongo} ..."

  koding.once 'dbClientReady', ->

    ComputeProvider      = rekuire 'computeproviders/computeprovider.coffee'
    JUser                = rekuire 'user/index.coffee'

    createUser = (u, next) ->

      console.log "\nCreating #{u.username} ... "

      JUser.count { username: u.username }, (err, count) ->

        if err then return console.error 'Failed to query count:', err

        if count > 0
          console.log "  User #{u.username} already exists, passing."
          return next()

        JUser.createUser u, (err, user, account) ->

          if err

            console.log "Failed to create #{u.username}: ", err
            if err.errors?
              console.log 'VALIDATION ERRORS: ', err.errors

            return next()

          account.update {
            $set          :
              type        : 'registered'
              globalFlags : ['super-admin']
          }, (err) ->

            if err?
              console.log "  Failed to activate #{u.username}:", err
              return next()

            console.log "  User #{user.username} created."
            console.log '\n   - Verifying email ...'

            user.confirmEmail (err) ->

              if err
                # RabbitMQ client is required to be initialized to send emails;
                # however send welcome emails is not reuqired here, so we silence it.
                if not /RabbitMQ client not found in Email/.test err
                  console.log '     Failed to verify: ', err
              else
                console.log '     Email verified.'

              console.log "\n   - Adding to group #{u.group} ..."

              JUser.addToGroup account, u.group, u.email, null, (err) ->

                if err then console.log '     Failed to add: ', err
                else        console.log "     Joined to group #{u.group}."

                client = {
                  connection : { delegate : account }
                  context    : { group    : u.group }
                }

                ComputeProvider.createGroupStack client, (err) ->

                  if err then console.log '     Failed to create stack: ', err
                  else        console.log "     Default stack created for #{u.group}."

                  next()


    # An array like this

    # users = [{
    #   username       : "gokmen"
    #   email          : "gokmen@koding.com"
    #   password       : "gokmen"
    #   passwordStatus : "valid"
    #   firstName      : "Gokmen"
    #   lastName       : "Goksel"
    #   group          : "koding"
    #   silence        : no
    # }]

    createUser users.shift(), createHelper = ->
      if   nextUser = users.shift()
      then createUser nextUser, createHelper
      else

        setTimeout ->
          console.log '\nALL DONE.'
          process.exit 0
        , 10000


fs  = require 'fs'
csv = require 'csv'

try

  data = fs.readFileSync './scripts/user-importer/team.csv'

  csv.parse data, { trim: yes }, (err, members) ->

    header = members.shift()
    users  = []

    members.forEach (member) ->

      return  if member.length isnt header.length

      item = {
        passwordStatus : 'valid'
        foreignAuth    : null
        silence        : no
      }

      for column, i in header
        item[column] = member[i]

      users.push item

    console.log "Read completed, #{users.length} item found."
    createUsers users
    console.log 'User import completed'

catch e

  console.log 'Failed to parse team.csv', e
  process.exit 0
