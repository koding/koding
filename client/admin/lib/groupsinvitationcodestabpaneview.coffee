GroupsInvitationCodeListItemView = require './views/groupsinvitationcodelistitemview'
GroupsInvitationTabPaneView = require './views/groupsinvitationtabpaneview'


module.exports = class GroupsInvitationCodesTabPaneView extends GroupsInvitationTabPaneView

  constructor:(options={}, data)->
    options.itemClass        = GroupsInvitationCodeListItemView
    options.noItemFound      = 'No invitation codes found.'
    options.noMoreItemFound  = 'No more invitation codes found.'
    options.unresolvedStatus = 'active'
    options.type             = 'InvitationCode'
    options.timestampField   = 'createdAt'

    super options, data

