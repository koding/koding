{Model} = require 'bongo'

module.exports = class JInvitationRequest extends Model

  @trait __dirname, '../traits/grouprelated'

  {Relationship}             = require 'jraphical'
  {ObjectRef, daisy, secure, signature} = require 'bongo'
  {permit}                   = require './group/permissionset'
  KodingError                = require '../error'

  @share()

  @set
    sharedEvents      :
      static          : []
      instance        : []
    indexes           :
      email           : 'sparse'
      status          : 'sparse'
    sharedMethods     :
      static          : {}
      instance        :
        remove        :
          (signature Function)
        approve       :
          (signature Function)
        decline       :
          (signature Function)
    schema            :
      requestedAt     :
        type          : Date
        default       : -> new Date
      resolvedAt      :
        type          : Date
      group           : String
      username        : String
      email           : String
      status          :
        type          : String
        enum          : ['Invalid status', ['pending', 'declined', 'approved']]
        default       : 'pending'
      invitationType  :
        type          : String
        enum          : ['invalid invitation type',[
          'invitation', 'basic approval'
        ]]
        default       : 'invitation'

  @resolvedStatuses = ['declined', 'approved']

  decline: permit 'send invitations',
    success: (client, callback=->)->
      @update $set:{ status: 'declined' }, callback

  remove$: permit 'send invitations',
    success: (client, callback=->)-> @remove callback

  approve: permit 'send invitations',
    success: (client, callback=->)->
      JGroup = require './group'
      JUser  = require './user'

      Relationship.one targetId: @getId(), as: 'owner', (err, rel)=>
        return callback err  if err
        JGroup.one {slug: @group}, (err, group)=>
          return callback err                           if err
          return callback 'Invalid invitation request'  unless @username or group.slug is client.context.group

          JUser.one {@username}, (err, user)=>
            return callback err  if err
            return callback new Error "User not found"  unless user
            user.fetchOwnAccount (err, requester)=>
              return callback err  if err
              @update $set:{ status: 'approved' }, (err)=>
                return callback err  if err
                if @invitationType is 'basic approval'
                  @approveApprovalRequest client, requester, group, callback
                else
                  @approveInvitationRequest client, requester, group, callback

  approveApprovalRequest: (client, account, group, callback)->
    group.approveMember account, (err)=>
      return callback err if err
      @sendRequestApprovedNotification client, account, group, callback

  approveInvitationRequest: (client, account, group, callback)->
    account.fetchUser (err, user)=>
      return callback err  if err
      group.fetchMembershipPolicy (err, policy)=>
        return callback err  if err
        options = {message: policy.communications.inviteApprovedMessage}
        group.inviteMember client, user.email, account, options, (err, invite)=>
          return callback err  if err
          @update $set:{ status: 'approved' }, callback

  sendRequestNotification:(group, actor, email, invitationType, callback=->)->
    JMailNotification = require './emailnotification'

    return callback 'group does not match with db'  unless group.slug is @group

    group.fetchAdmins (err, receivers)=>
      return callback err  if err

      if invitationType is 'invitation'
        event = 'InvitationRequested'
      else
        event = 'ApprovalRequested'

      for receiver in receivers when receiver
        receiver.sendNotification 'GroupAccessRequested',
          actionType : 'groupAccessRequested'
          actorType  : 'requester'
          requester  : ObjectRef(actor).data
          subject    : ObjectRef(group).data

        data = {
          actor, receiver, event
          contents          :
            subject         : ObjectRef(group).data
            actionType      : 'approvalRequest'
            actorType       : 'requester'
            approvalRequest : ObjectRef(this).data
            requester       : ObjectRef(actor).data
        }
        JMailNotification.create data, callback

  sendRequestApprovedNotification:(client, receiver, group, callback)->
    JAccount          = require './account'
    JMailNotification = require './emailnotification'

    actor = client.connection.delegate

    receiver.sendNotification 'GroupRequestApproved',
      actionType   : 'groupRequestApproved'
      actorType    : 'admin'
      subject      : ObjectRef(group).data
      admin        : ObjectRef(receiver).data

    data = {
      actor, receiver
      event        : 'Approved'
      contents     :
        subject    : ObjectRef(group).data
        actionType : 'approved'
        actorType  : 'requester'
        approved   : ObjectRef(this).data
        requester  : ObjectRef(actor).data
    }
    JMailNotification.create data, callback
