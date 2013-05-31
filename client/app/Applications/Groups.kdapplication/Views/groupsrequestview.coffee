class GroupsRequestView extends JView

  requestLimit: 5

  updateCurrentState:->
    group = @getData()
    group.countPendingInvitationRequests (err, countReq)=>
      if err then console.error error
      else
        group.countPendingSentInvitations (err, countInv)=>
          if err then console.error error
          else
            reqPhrase = if countReq is 1 then 'approval' else 'approvals'
            invPhrase = if countInv is 1 then 'invitation' else 'invitations'
            @currentState.updatePartial """
              There are #{countReq} waiting #{reqPhrase} and #{countInv} unacknowledged #{invPhrase}.
              """

  fetchSomeRequests:(invitationType='invitation', status, timestamp, callback)->
    [callback, timestamp] = [timestamp, callback]  unless callback

    invitationType = { $in: invitationType }  if Array.isArray invitationType
    status = { $in: status }  if Array.isArray status

    group = @getData()

    if timestamp
      selector  = { timestamp: $lt: timestamp }

    targetSelector = { invitationType }
    targetSelector.status = status  if status?

    options   =
      targetOptions : 
        selector    : targetSelector
        limit       : @requestLimit
        sort        : { requestedAt: -1 }
      options       :
        sort        : { timestamp: -1 }

    group.fetchInvitationRequests selector, options, callback