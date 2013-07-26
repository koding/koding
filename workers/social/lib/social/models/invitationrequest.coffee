{Model} = require 'bongo'

module.exports = class JInvitationRequest extends Model

  @trait __dirname, '../traits/grouprelated'

  {ObjectRef, daisy, secure} = require 'bongo'
  {permit}    = require './group/permissionset'
  KodingError = require '../error'

  @share()

  @set
    indexes           :
      email           : 'sparse'
      status          : 'sparse'
    sharedMethods     :
      static          : ['create']
      instance        : ['send', 'remove', 'approve', 'decline']
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
        enum          : ['Invalid status', [
          'pending', 'sent', 'declined', 'approved'
        ]]
        default       : 'pending'
      invitationType  :
        type          : String
        enum          : ['invalid invitation type',[
          'invitation', 'basic approval'
        ]]
        default       : 'invitation'
    relationships   :
      requester     :
        targetType  : 'JAccount'
        as          : 'requester'
      invitation    :
        targetType  : 'JInvitation'
        as          : 'owner'

  @resolvedStatuses = ['declined', 'approved']

  decline: permit 'send invitations',
    success: (client, callback=->)->
      @update $set:{ status: 'declined' }, callback

  remove$: permit 'send invitations',
    success: (client, callback=->)-> @remove callback

  approve: permit 'send invitations',
    success: (client, callback=->)->
      if @invitationType is 'basic approval'
        @approveApprovalRequest client, callback
      else
        @approveInvitationRequest client, callback

  approveApprovalRequest: (client, callback=->)->
    @update $set:{ status: 'approved' }, (err)=>
      return callback err if err
      @sendRequestApprovedNotification client, group, account, callback

  approveInvitationRequest: (client, options, callback)->
    [callback, options] = [options, callback]  unless callback
    JGroup      = require './group'

    @sendMail client, @koding, group, options, (err)=>
      return callback err  if err
      @addInvitation invite, (err)=>
        return callback err  if err
        @update $set:{ status: 'sent' }, callback

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

  sendRequestApprovedNotification:(client, group, receiver, callback)->
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
