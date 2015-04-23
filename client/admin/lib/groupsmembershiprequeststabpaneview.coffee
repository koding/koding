GroupsInvitationTabPaneView = require './views/groupsinvitationtabpaneview'


module.exports = class GroupsMembershipRequestsTabPaneView extends GroupsInvitationTabPaneView

  constructor:(options={}, data)->
    options.noItemFound      = 'No requests found.'
    options.noMoreItemFound  = 'No more requests found.'
    options.unresolvedStatus = 'pending'
    options.type             = 'InvitationRequest'
    options.timestampField   = 'requestedAt'

    super options, data

    @getData().on 'NewInvitationRequest', =>
      @emit 'NewInvitationActionArrived'
      @parent.tabHandle.markDirty()



