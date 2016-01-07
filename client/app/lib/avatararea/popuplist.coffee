kd                  = require 'kd'
KDListView          = kd.ListView


module.exports  = class PopupList extends KDListView

  constructor:(options = {}, data)->

    options.tagName     or= "ul"
    options.cssClass    or= "avatararea-popup-list"
    # options.lastToFirst  ?= no

    super options,data
