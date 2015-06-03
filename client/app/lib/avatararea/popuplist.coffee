kd                  = require 'kd'
KDListView          = kd.ListView
AvatarAreaConstants = require './avatarareaconstants'


module.exports  = class PopupList extends KDListView

  constructor:(options = {}, data)->

    options.tagName     or= "ul"
    options.cssClass    or= "avatararea-popup-list"
    # options.lastToFirst  ?= no

    super options,data

    notifListItemClicked = AvatarAreaConstants.events.NOTIF_LIST_ITEM_CLICKED

    @on notifListItemClicked, =>
      @getDelegate().emit notifListItemClicked

