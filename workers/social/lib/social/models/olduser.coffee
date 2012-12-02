
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
            'unregistered','registered','confirmed','failed'
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
                    nickname  : user.nickname
                    firstName : user.firstName
                    lastName  : user.lastName
                  , (err)-> console.error if err
              else
                errors.push {error, user}
                user.update $set: status: 'failed', ->

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

  @getTextBody = ({requestedAt, url, firstName, lastName, nickname})->
    """
    Hello,

    TL;DR: Your KODINGEN account is now a brand new KODING account - and it is ready for you!


    You've signed up for Kodingen.com maybe a loooong time ago. Sorry it took so long for us to send you this email. Finally the wait is over (YAY!). We have reached to the scariest moment of a startup where we say "here is our product!".

    Thank you for signing up to Kodingen, thanks for giving us a chance. It means so much to us.

    If you have a moment, I want to tell you 'why Koding' - "Welcome to Koding, the next little thing." it’s here: http://d.pr/SGu7

    We had a nice write-up on TechCrunch when we first launched our new version back in July: http://techcrunch.com/2012/07/24/koding-launch/

    Alright, here is your new account, we hope you will like what you see.

    Your username: #{nickname} (you've registered this to Kodingen)
    #{url}


    Now, go, code, share and have fun!
    (Please take a look at http://wiki.koding.com for the things you can do)

    Whole Koding Team welcomes you,
    Devrim, Sinan, Chris, Aleksey, Gokmen, Arvid, Richard and Nelson (yeah we're just 8*)


    notes:
    - of course you can mail me back if you like... (says Devrim)
    - this is still beta, expect bugs, please don’t be surprised if you spot one.
    - no matter how you signed up, you will not receive any mailings, newsletters and other crap.
    - if you’ve never signed up (sometimes people type their emails wrong, and it happens to be yours), please let us know.
    - if you want to change your username, just send yourself an invite from the platform, and register a new account.

    - IMPORTANT: We did NOT migrate your files or databases at Kodingen just yet, we will provide an app for that soon, or you can do it yourself (ftp, ftps, curl, wget etc.)

    *if you fall in love with this project, please let us know - http://blog.koding.com/2012/06/we-want-to-date-not-hire/



    """


















