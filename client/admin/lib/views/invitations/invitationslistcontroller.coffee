kd                    = require 'kd'
remote                = require('app/remote').getInstance()
InvitedItemView       = require './inviteditemview'
KDNotificationView    = kd.NotificationView
KodingListController  = require 'app/kodinglist/kodinglistcontroller'


module.exports = class InvitationsListController extends KodingListController

  constructor: (options = {}, data) ->

    options.noItemFoundText            ?= 'There is no pending invitation.'
    options.statusType                or= 'pending'
    options.itemClass                 or= InvitedItemView
    options.lazyLoadThreshold          ?= .99
    options.viewOptions               or= {}
    options.viewOptions.wrapper        ?= yes
    options.viewOptions.itemOptions   or= options.listViewItemOptions

    super options, data


  addListItems: (items = []) ->

    super

    @emit 'ShowSearchContainer'
    @showNoItemWidget()           unless items.length


  bindEvents: ->

    super

    listView = @getListView()
    listView.on 'ItemAction', ({ action, item }) =>

      switch action
        when 'Resend' then  @resend item


  removeItem: (item) ->

    listView = @getListView()

    item.getData().remove (err) ->
      unless err
        listView.emit 'ItemAction', { action : 'ItemRemoved', item }
        return

      item.revokeButton.hideLoader()

      new KDNotificationView
        title    : 'Unable to revoke invitation. Please try again.'
        duration : 5000


  resend: (item) ->

    remote.api.JInvitation.sendInvitationByCode item.getData().code, (err) ->
      item.resendButton.hideLoader()
      title    = 'Invitation is resent.'
      duration = 5000

      if err
        title  = 'Unable to resend the invitation. Please try again.'

      item.timeAgoView.setData new Date  unless err

      return new KDNotificationView { title, duration }
