
jraphical   = require 'jraphical'
KodingError = require '../error'

module.exports = class JOldUser extends jraphical.Module
  log4js            = require "log4js"
  log               = log4js.getLogger("[JOldUser]")

  JUser             = require './user'
  JPasswordRecovery = require './passwordrecovery'
  {Relationship}    = jraphical

  {secure}          = require 'bongo'
  csvParser         = require 'csv'
  createSalt        = require 'hat'
  dateFormat        = require 'dateformat'

  @share()
  @set
    indexes:
      'nickname'          : 'unique'
    sharedMethods         :
      static              : [
        '__importKodingenUsers', '__migrateKodingenUsers', '__currentState'
      ]
    schema                :
      nickname            :
        type              : String
        validate          : (value)->
          3 < value.length < 26 and /^[a-z0-9][a-z0-9-]+$/.test value
        set               : (value)-> value.toLowerCase()
      status              :
        type              : String
        enum              : [
          'invalid status type', [
            'unregistered','registered','confirmed'
          ]
        ]
        default           : 'unregistered'
      firstName           :
        type              : String
        required          : yes
      lastName            :
        type              : String
        default           : ''
      email               :
        type              : String
        email             : yes

  @__importKodingenUsers = secure ({connection}, options, callback)->

    unless connection.delegate?.can? 'migrate-kodingen-users'
      callback null
      console.error "Not authorized request from", connection.delegate?.profile?.nickname
    else
      pathToKodingenCSV = "#{process.cwd()}/../../wp_users.csv"
      console.log "Parsing: ", pathToKodingenCSV

      limit      = options.limit or 0
      iterations = 0
      users_list = []

      csv = csvParser().from pathToKodingenCSV, escape '\\'

      csv.on 'record', (line, lineNumber)->
        if iterations < limit or limit is 0
          f_name = line[9].slice(0, line[9].indexOf(' ')) or line[9]
          l_name = line[9].slice line[9].indexOf(' ')+1

          olduser = new JOldUser
            email     : line[4]
            lastName  : l_name
            firstName : f_name
            nickname  : line[1]

          iterations += 1 if limit isnt 0

          if limit isnt 0 and iterations is limit
            csv.end()

          olduser.save (err)->
            console.error "Validation error occured while saving #{line[1]} at #{lineNumber}." if err

      csv.on 'end', (count)->
        if limit is 0 or limit is iterations
          callback "Finished to import accounts.", count
          iterations = limit+1

      csv.on 'error', (err)->
        console.error "Parsing err:", err #errors.push err

  @__migrateKodingenUsers = secure (client, options, callback)->

    {connection} = client
    unless connection.delegate?.can? 'migrate-kodingen-users'
      callback null, "You are not authorized to do this."
      console.error "Not authorized request from", connection.delegate?.profile?.nickname
    else
      limit = options.limit or 10

      JOldUser.some {status: "unregistered"}, {limit}, (err, old_users)->

        accounts = []
        errors   = []
        register = (users, index, cb)->
          user = users[index]
          if not user then cb()
          else
            pass = createSalt()
            JUser.register client,
              email           : user.email
              firstName       : user.firstName
              lastName        : user.lastName
              password        : pass
              passwordConfirm : pass
              username        : user.nickname
              agree           : "on"
              inviteCode      : "twitterfriends"
              silence         : yes
            , (error, account, token)->
              if not err and account
                accounts.push account
                user.update $set: status: 'registered', ->
                JUser.one {username : user.nickname}, (_err, new_user)->
                  JPasswordRecovery.create client,
                    email     : user.email
                    expiresAt : new Date Date.now() + 1000 * 60 * 60 * 24 * 7 # 7 days
                    subject   : JOldUser.getSubject
                    textbody  : JOldUser.getTextBody
                  , (err)-> console.error if err
              else
                errors.push {error, user}

              if index < users.length
                register users, index+1, cb
              else
                cb()

        if old_users.length is 0
          callback null, "There is no unregistered users left in KodingenUsers collection."
        else
          register old_users, 0, ->
            callback errors, "From #{old_users.length} unregistered Kodingen user, #{accounts.length} account created."

  @__currentState = secure (client, callback)->

    {connection} = client
    unless connection.delegate?.can? 'migrate-kodingen-users'
      callback "You are not authorized to do this."
      console.error "Not authorized request from", connection.delegate?.profile?.nickname
    else
      JOldUser.count {status: "unregistered"}, (err, unregistered)->
        if err then callback err
        else callback "There are #{unregistered} not migrated Kodingen members."

  @getSubject = -> '[Koding] A new Koding account created for an old friend!'

  @getTextBody = ({requestedAt, url})->
    """
    At #{dateFormat requestedAt, 'shortTime'} on #{dateFormat requestedAt, 'shortDate'} we've created a Koding account for you!

    There is a one-time token which allow you to reset your password. This token will self-destruct 7 days after it is created.

    #{url}

    Have fun!
    """
