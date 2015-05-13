kd                    = require 'kd'
KDView                = kd.View
remote                = require('app/remote').getInstance()
InvitedItemView       = require './inviteditemview'
TeamMembersCommonView = require '../members/teammemberscommonview'


module.exports = class PendingInvitationsView extends TeamMembersCommonView

  constructor: (options = {}, data) ->

    options.listViewItemClass   = InvitedItemView
    options.statusType        or= 'pending'

    super options, data


  fetchMembers: ->

    return if @isFetching

    @isFetching    = yes
    { statusType } = @getOptions()

    selector = status: statusType
    options  = { @skip }

    remote.api.JInvitation.some selector, options, (err, invitations) =>

      if err
        @listController.lazyLoader.hide()
        return kd.warn err

      @listMembers invitations
      @isFetching = no
