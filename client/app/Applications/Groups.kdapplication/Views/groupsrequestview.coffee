class GroupsRequestView extends JView

  prepareBulkInvitations:->
    group = @getData()
    group.countPendingInvitationRequests (err, count)=>
      if err then console.error error
      else
        [toBe, people] = if count is 1 then ['is','person'] else ['are','people']
        @currentState.updatePartial """
          There #{toBe} currently #{count} #{people} waiting for an invitation
          """

  fetchSomeRequests:(invitationType='invitation', status, callback)->
    [callback, status] = [status, callback]  unless callback

    invitationType = { $in: invitationType }  if Array.isArray invitationType
    status = { $in: status }  if Array.isArray status

    group = @getData()

    selector  = { timestamp: $gte: @timestamp }

    targetSelector = { invitationType }
    targetSelector.status = status  if status?

    options   =
      targetOptions : { selector: targetSelector }
      sort          : { timestamp: -1 }
      limit         : 20

    group.fetchInvitationRequests selector, options, callback