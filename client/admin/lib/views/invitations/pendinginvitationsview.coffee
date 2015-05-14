kd                    = require 'kd'
KDView                = kd.View
remote                = require('app/remote').getInstance()
InvitedItemView       = require './inviteditemview'
TeamMembersCommonView = require '../members/teammemberscommonview'


module.exports = class PendingInvitationsView extends TeamMembersCommonView

  constructor: (options = {}, data) ->

    options.listViewItemClass        = InvitedItemView
    options.searchInputPlaceholder   = 'Find by email or first name'
    options.listViewItemOptions    or= statusType: 'pending'
    options.statusType             or= 'pending'

    super options, data


  fetchMembers: ->

    return if @isFetching

    @isFetching    = yes
    { statusType } = @getOptions()
    query          = @searchInput.getValue()
    options        = { @skip }
    method         = 'some'
    selector       = status: statusType

    if query
      method = 'search'
      selector.query = query

    remote.api.JInvitation[method] selector, options, (err, invitations) =>

      if err
        @listController.lazyLoader.hide()
        return kd.warn err

      @listMembers invitations
      @isFetching = no
