{Model} = require 'bongo'

module.exports = class JInvitationRequest extends Model

  {daisy}   = require 'bongo'

  {permit} = require './group/permissionset'

  KodingError = require '../error'

  #csvParser = require 'csv'

  @share()

  @set
    indexes           :
      email           : ['unique','sparse']
      status          : 'sparse'
    sharedMethods     :
      static          : ['create'] #,'__importKodingenUsers']
      instance        : ['sendInvitation','deleteInvitation']
    schema            :
      email           :
        type          : String
        email         : yes
        required      : no
      koding          :
        username      : String
      kodingen        :
        isMember      : Boolean
        username      : String
        registeredAt  : Date
      requestedAt     :
        type          : Date
        default       : -> new Date
      group           : String
      status          :
        type          : String
        enum          : ['Invalid status', [
          'pending'
          'sent'
          'declined'
          'approved'
        ]]
        default       : 'pending'
      invitationType  :
        type          : String
        enum          : ['invalid invitation type',[
          'invitation'
          'basic approval'
        ]]
        default       : 'invitation'

  @create =({email}, callback)->
    invite = new @ {email}
    invite.save (err)->
      console.log "->",arguments
      if err
        callback err
      else
        callback null, email

  @__importKodingenUsers =do->
    pathToKodingenCSV = 'kodingen/wp_users.csv'
    (callback)->
      queue = []
      errors = []
      eterations = 0
      csv = csvParser().fromPath pathToKodingenCSV, escape: '\\'
      csv.on 'data', (datum)->
        if datum[0] isnt 'ID'
          deleted = datum.pop()+''
          spam    = datum.pop()+''
          if '1' in [deleted, spam]
            reason = {deleted, spam}
            csv.emit 'error', "this datum is invalid because #{JSON.stringify reason}"
          else
            queue.push ->
              [__id, username, __hashedPassword, __nicename, email, __url, registeredAt] = datum
              inviteRequest = new JInvitationRequest {
                email
                kodingen    : {
                  isMember  : yes
                  username
                  registeredAt: Date.parse registeredAt
                }
              }
              inviteRequest.save queue.next.bind queue
      csv.on 'end', (count)->
        callback "Finished parsing #{count} records, of which #{queue.length} were valid."
        daisy queue
      csv.on 'error', (err)-> errors.push err

  deleteInvitation: permit 'send invitations'
    success:(client, rest...)-> @remove rest...

  sendInvitation: permit 'send invitations'
    success: (client, callback)->
      JUser         = require './user'
      JInvitation   = require './invitation'
      JUser.someData username: @koding.username, {email:1}, (err, cursor)=>
        if err then callback err
        else
          cursor.nextObject (err, obj)=>
            if err then callback err
            else unless obj?
              callback new KodingError "Unknown username: #{@koding.username}"
            else
              JInvitation.sendBetaInvite obj, (err)=>
                if err then callback err
                else @update $set: status: 'sent', (err)-> callback err
