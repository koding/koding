class PopupList extends KDListView

  constructor:(options = {}, data)->

    options.tagName     or= "ul"
    options.cssClass    or= "avatararea-popup-list"
    # options.lastToFirst or= no

    super options,data
