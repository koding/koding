{Model} = require 'bongo'

module.exports = class JInvitationRequest extends Model

  @trait __dirname, '../traits/grouprelated'

  {ObjectRef, daisy, secure}   = require 'bongo'

  {permit} = require './group/permissionset'

  KodingError = require '../error'

  #csvParser = require 'csv'

  @share()

  @set
    indexes           :
      #email           : ['unique','sparse']
      email           : 'sparse'
      status          : 'sparse'
    sharedMethods     :
      static          : ['create', 'count'] #,'__importKodingenUsers']
      instance        : [
        'sendInvitation', 'deleteInvitation'
        'approve', 'declineInvitation'
        'acceptInvitationByInvitee', 'ignoreInvitationByInvitee'
      ]
    schema            :
      email           :
        type          : String
        email         : yes
        required      : no
      koding          :
        username      : String
        fullName      : String
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
          'pending', 'sent', 'declined', 'approved', 'ignored', 'accepted'
        ]]
        default       : 'pending'
      invitationType  :
        type          : String
        enum          : ['invalid invitation type',[
          'invitation', 'basic approval'
        ]]
        default       : 'invitation'

  @resolvedStatuses = ['declined', 'approved', 'ignored', 'accepted']

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

  deleteInvitation: permit 'send invitations',
    success: (client, callback=->)->
      JInvitation = require './invitation'

      @remove (err)=>
        return callback err  if err
        selector = inviteeEmail: @email, status: 'sent', group: @group
        JInvitation.one selector, (err, invitation)->
          return callback err  if err or not invitation
          invitation.remove callback

  fetchAccount:(callback)->
    JAccount = require './account'
    if @koding?.username
      JAccount.one {'profile.nickname': @koding.username}, callback
    else if @email
      JUser = require './user'
      JUser.one email:@email, (err, user)->
        if err then callback err
        else JAccount.one {'profile.nickname':user.username}, callback
    else
      callback new KodingError """
        Unimplemented: we can't fetch an account from this type of invitation
        """

  approve: permit 'send invitations',
    success: (client, callback=->)->
      if @invitationType is 'basic approval'
        @approveRequest client, callback
      else
        @approveInvitation client, callback

  approveRequest: (client, callback=->)->
    JGroup = require './group'
    JGroup.one { slug: @group }, (err, group)=>
      if err then callback err
      else unless group?
        callback new KodingError "No group! #{@group}"
      else
        @fetchAccount (err, account)=>
          return callback err if err
          group.approveMember account, (err)=>
            return callback err if err
            @update $set:{ status: 'approved' }, (err)=>
              return callback err if err
              @sendRequestApprovedNotification client, group, account, callback

  approveInvitation: (client, options, callback=->)->
    JGroup      = require './group'
    JInvitation = require './invitation'

    JGroup.one { slug: @group }, (err, group)=>
      if err then callback err
      else unless group?
        callback new KodingError "No group! #{@group}"
      else
        if @koding?.username
          @sendInviteMailToKodingUser client, @koding, group, options, (err)=>
            return callback err if err
            @update $set:{ status: 'sent' }, callback
        else
          JInvitation.one {inviteeEmail: @email}, (err, invite)=>
            return callback err if err
            group.fetchMembershipPolicy (err, policy)=>
              if message = policy.communications.inviteApprovedMessage
                group.invitationMessage = message

              JInvitation.sendEmailForInviteViaGroup client, invite, group, options, (err)=>
                return callback err if err
                @update $set:{ status: 'sent' }, callback

  fetchDataForAcceptOrIgnore: (client, callback)->
    {delegate} = client.connection
    JGroup = require './group'
    JGroup.one slug:@group, (err, group)=>
      if err then callback err
      else unless group?
        callback new KodingError "No group! #{@group}"
      else @fetchAccount (err, account)=>
        if err then callback err
        else if not account
          callback new KodingError "Account ID does not equal caller's ID"
        else if not account._id.equals delegate.getId()
          callback new KodingError "Account ID does not equal caller's ID"
        else callback null, account, group

  acceptInvitationByInvitee: secure (client, callback)->
    @fetchDataForAcceptOrIgnore client, (err, account, group)=>
      if err then callback err
      else
        group.approveMember account, (err)=>
          if err then callback err
          else @update $set:{status:'accepted'}, (err)->
            if err then callback err
            else callback null

  ignoreInvitationByInvitee: secure (client, callback)->
    @fetchDataForAcceptOrIgnore client, (err, account, group)=>
      if err then callback err
      else
        @update $set:{status:'ignored'}, (err)->
          if err then callback err
          else callback null

  sendInvitation:(client, message, options, callback=->)->
    [callback, options] = [options, callback]  unless callback

    JUser       = require './user'
    JGroup      = require './group'
    JInvitation = require './invitation'

    JGroup.one slug: @group, (err, group)=>
      if err then callback err
      else unless group?
        callback new KodingError "No group! #{@group}"
      else
        JUser.one email: @email, (err, user)=>
          if err then callback err
          else if not user
            # send invite to non koding user
            JInvitation.createViaGroup client, group, [@email], options, callback
          else
            @update $set:{'koding.username':user.username}, (err)=>
              if err then callback err
              else
                # send invite to existing koding user
                @sendInviteMailToKodingUser client, user, group, message, options, callback

  sendInvitation$: permit 'send invitations',
    success: (client, message, options, callback)-> @sendInvitation client, message, options, callback

  sendInviteMailToKodingUser:(client, user, group, message, options, callback)->
    [callback, options] = [options, callback]  unless callback
    options ?= {}

    JAccount          = require './account'
    JMailNotification = require './emailnotification'

    JAccount.one 'profile.nickname': user.username, (err, receiver)=>
      if err then callback err
      else
        {delegate} = client.connection
        JAccount.one _id: delegate.getId(), (err, actor)=>
          if err then callback err
          else
            data =
              actor        : actor
              receiver     : receiver
              event        : 'Invited'
              contents     :
                subject    : ObjectRef(group).data
                actionType : 'invite'
                actorType  : 'admin'
                invite     : ObjectRef(@).data
                admin      : ObjectRef(client).data
                message    : message

            data.bcc = options.bcc  if options.bcc

            receiver.sendNotification 'GroupInvited',
              actionType : 'groupInvited'
              actorType  : 'inviter'
              inviter    : ObjectRef(actor).data
              subject    : ObjectRef(group).data

            JMailNotification.create data, (err)->
              if err then callback new KodingError "Could not send"
              else callback null

  sendRequestNotification:(client, email, invitationType, callback=->)->
    JUser             = require './user'
    JAccount          = require './account'
    JGroup            = require './group'
    JMailNotification = require './emailnotification'

    JGroup.one slug: @group, (err, group)=>
      if err then callback err
      else unless group?
        callback new KodingError "No group! #{@group}"
      else
        cb = (actor, actorData)=>
          group.fetchAdmins (err, accounts)=>
            if err then callback err

            if invitationType is 'invitation'
              event = 'InvitationRequested'
            else
              event = 'ApprovalRequested'

            for account in accounts when account
              data =
                actor             : actor
                receiver          : account
                event             : event
                contents          :
                  subject         : ObjectRef(group).data
                  actionType      : 'approvalRequest'
                  actorType       : 'requester'
                  approvalRequest : ObjectRef(@).data
                  requester       : actorData

              account.sendNotification 'GroupAccessRequested',
                actionType : 'groupAccessRequested'
                actorType  : 'requester'
                requester  : ObjectRef(actor).data
                subject    : ObjectRef(group).data

              JMailNotification.create data, (err)->
                if err then callback new KodingError "Could not send"
                else callback null

        {delegate} = client.connection
        if delegate instanceof JAccount
          JAccount.one _id: delegate.getId(), (err, actor)=>
            return callback err  if err
            cb actor, ObjectRef(actor).data
        else
          cb email, email

  sendRequestApprovedNotification:(client, group, account, callback)->
    JAccount          = require './account'
    JMailNotification = require './emailnotification'

    {delegate} = client.connection
    JAccount.one _id: delegate.getId(), (err, actor)=>
      if err then callback err
      else
        data =
          actor             : actor
          receiver          : account
          event             : 'Approved'
          contents          :
            subject         : ObjectRef(group).data
            actionType      : 'approved'
            actorType       : 'requester'
            approved        : ObjectRef(@).data
            requester       : ObjectRef(actor).data

        account.sendNotification 'GroupRequestApproved',
          actionType : 'groupRequestApproved'
          actorType  : 'admin'
          subject    : ObjectRef(group).data
          admin      : ObjectRef(account).data

        JMailNotification.create data, (err)->
          if err then callback new KodingError "Could not send"
          else callback null

  @count$ = permit 'send invitations',
    success:({context:{group}}, selector, callback)->
      [callback, selector] = [selector, callback]  unless callback
      selector ?= {}
      selector.group = if Array.isArray group then $in: group else group
      @count selector, callback

  save:(callback)->
    super
    unless @koding?.username # JUnsubscribedMail is not for koding users
      JUnsubscribedMail = require './unsubscribedmail'
      JUnsubscribedMail.removeFromList @email
