GroupsInvitationTabPaneView = require './views/groupsinvitationtabpaneview'


module.exports = class GroupsSentInvitationsTabPaneView extends GroupsInvitationTabPaneView

  constructor:(options={}, data)->
    options.noItemFound      = 'No sent invitations found.'
    options.noMoreItemFound  = 'No more sent invitations found.'
    options.unresolvedStatus = 'sent'
    options.type             = 'Invitation'
    options.timestampField   = 'createdAt'

    super options, data
