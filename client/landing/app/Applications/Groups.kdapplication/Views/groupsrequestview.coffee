class GroupsRequestView extends JView

  requestLimit: 5

  prepareBulkInvitations:->
    group = @getData()
    group.countPendingInvitationRequests (err, countReq)=>
      if err then console.error error
      else
        group.countPendingSentInvitations (err, countInv)=>
          if err then console.error error
          else
            reqPhrase = if countReq is 1 then 'person' else 'people'
            @currentState.updatePartial """
              Currently there are #{countReq} #{reqPhrase} waiting for an invitation or approval and #{countInv} sent invitations unanswered.
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
      options       :
        sort        : { timestamp: -1 }

    group.fetchInvitationRequests selector, options, callback