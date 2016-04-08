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
    options.lazyLoadThreshold         or= .99
    options.viewOptions               or= {}
    options.viewOptions.wrapper       or= yes
    options.viewOptions.itemOptions   or= options.listViewItemOptions

    options.fetcherMethod             or= (selector, fetchOptions, callback) ->

      method          = if selector.query then 'search' else 'some'
      selector.status = options.statusType

      remote.api.JInvitation[method] selector, fetchOptions, (err, invitations) ->
        callback err, invitations

    super options, data


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

      item.timeAgoView.setData new Date
      return new KDNotificationView { title, duration }
