class CommentSettingsButton extends KDButtonViewWithMenu

  constructor: (options = {}, data) ->

    options.cssClass       = KD.utils.curry "activity-settings-menu", options.cssClass
    options.style          = "comment-menu"
    options.itemChildClass = ActivityItemMenuItem
    options.title          = ""
    options.icon           = yes
    options.iconClass      = "arrow"
    options.callback       = @bound "contextMenu"

    super options, data
