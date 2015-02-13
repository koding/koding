class AvatarChangeHeaderView extends JView

  constructor: (options={}, data)->

    options.tagName  = "article"
    options.cssClass = "avatar-change-header"
    super options, data

  viewAppended: ->
    super
    options = @getOptions()

    if options.title
      @addSubView new KDCustomHTMLView
        tagName: "strong"
        partial: options.title

    if options.buttons?.length > 0
      for button in options.buttons
        @addSubView button
