{Model} = require 'bongo'

module.exports = class JInvitationRequest extends Model
  {ObjectRef, daisy}   = require 'bongo'

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
      instance        : [
        'sendInvitation'
        'deleteInvitation'
        'approveInvitation'
        'declineInvitation'
      ]
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

  declineInvitation: permit 'send invitations',
    success: (client, callback=->)->
      @update $set:{ status: 'declined' }, callback

  fetchAccount:(callback)->
    JAccount = require './account'
    if @koding.username
      JAccount.one {'profile.nickname': @koding.username}, callback
    else
      callback new KodingError """
        Unimplemented: we can't fetch an account from this type of invitation
        """

  approveInvitation: permit 'send invitations',
    success: (client, callback=->)->
      JGroup = require './group'
      JGroup.one { slug: @group }, (err, group)=>
        if err then callback err
        else unless group?
          callback new KodingError "No group! #{@group}"
        else
          @fetchAccount (err, account)=>
            if err then callback err
            else
              # send the invitation in any case:
              @sendInvitation client, group
              if account?
                group.approveMember account, (err)=>
                  if err then callback err
                  else @update $set:{ status: 'approved' }, callback
              else
                @update $set:{ status: 'sent' }, callback

  deleteInvitation: permit 'send invitations',
    success:(client, rest...)-> @remove rest...

  sendInvitation:(client, callback=->)->
    JUser       = require './user'
    JInvitation = require './invitation'
    JGroup      = require './group'

    JGroup.one slug: @group, (err, group)=>
      if err then callback err
      else unless group?
        callback new KodingError "No group! #{@group}"
      else
        JUser.one email: @email, (err, user)=>
          if err then callback err
          else if not user
            # send invite to non koding user
          else
            # send invite to existing koding user
            @sendInviteToKodingUser client, user, group, callback

  sendInvitation$: permit 'send invitations',
    success: (client, callback)-> @sendInvitation client, callback

  sendInviteToKodingUser:(client, user, group, callback)->
    JMailNotification = require './emailnotification'

    data =
      actor        : client
      receiver     : user
      event        : 'Invited'
      contents     :
        subject    : ObjectRef(@).data
        actionType : 'group'
        actorType  : 'admin'
        group      : ObjectRef(group).data
        admin      : ObjectRef(client).data

    JMailNotification.create data, (err)->
      if err then callback new KodingError "Could not send"
      else
        callback null
