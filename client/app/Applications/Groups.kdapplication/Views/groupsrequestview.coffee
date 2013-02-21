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

  fetchSomeRequests:(invitationType='invitation', callback)->

    group = @getData()

    selector  = { timestamp: $gte: @timestamp }
    options   =
      targetOptions : { selector: { invitationType } }
      sort          : { timestamp: -1 }
      limit         : 20

    group.fetchInvitationRequests selector, options, callback