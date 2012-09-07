{Model} = require 'bongo'

JSession = require './session'
JUser = require './user'
KodingError = require '../../error'

module.exports = class JVisitor extends Model
  {secure} = require 'bongo'

  @share()

  @set
    sharedMethods :
      static      : ['on','getVersion','isRegistrationEnabled']
      instance    : ['start','on','off','many','once']
    schema        :
      createdAt   :
        type      : Date
        default   : -> new Date
      clientId    : String

  {defineProperty} = Object

  defineProperty(@, 'visitors', value: {})
  defineProperty(@, 'guests', value: {})
  defineProperty(@, 'users', value: {})

  @isRegistrationEnabled =(callback)->
    JRegistrationPreferences.one {}, (err, prefs)->
      callback err? or prefs?.isRegistrationEnabled or no

  @getVersion=(callback)->
    fs.readFile "./.revision",'utf-8',(err,data)->
      version = data.replace("\n", "")
      callback null,version

  createGuest:(connection)->
    visitor = @
    {constructor} = visitor
    connection.remote.fetchClientId (clientId)->
      guest = new JGuest {clientId}
      guest.save (err, docs)->
        if err
          visitor.emit 'error', err
        else
          connection.delegate = guest
          {guestId} = guest
          constructor.guests[guestId] = guest
          session = new JSession {
            clientId
            guestId
          }
          session.save (err)->
            if err
              visitor.emit 'error', err
            else
              visitor.emit ['change','logout'], guest

  @authenticateClient:(client, callback=->)->
    JSession.one {clientId: client.sessionToken}, (err, session)->
      if err or not session?
        callback new KodingError 'Authentication failed!'
      else
        {username} = session
        JUser.one {username}, (err, user)->
          if err
            callback? err
          else
            user.fetchOwnAccount (err, account)->
              if err
                callback? err
              else
                client.connection = delegate: account
                callback null, account

  start: secure ({connection}, callback)->
    visitor = @
    {constructor} = visitor
    connection.remote.fetchClientId (clientId)->
      constructor.visitors[clientId] = visitor
      JSession.one {clientId}, (err, session)->
        if err
          callback? err
        else
          unless session
            visitor.createGuest connection
          else if session.username
            {username} = session
            JUser.one {username}, (err, user)->
              if err
                callback? err
              else
                user.fetchOwnAccount (err, account)->
                  if err
                    callback? err
                  else
                    connection.delegate = account
                    setTimeout ->
                      visitor.emit ['change','login'], account
                    , 5000
                    callback? null
          else
            {guestId} = session
            JGuest.one {guestId}, (err, guest)->
              if err
                callback? err
              else unless guest
                JSession.remove {clientId}, (err)->
                  if err
                    callback? err
                  else
                    visitor.createGuest connection
              else
                connection.delegate = guest
                setTimeout ->
                  visitor.emit ['change','logout'], guest
                , 5000
                callback? null
                # visitor.uber 'save', callback