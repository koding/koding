class KDOverlayView extends KDView

  constructor: (options={}, data)->

    {isRemovable, animated, color, transparent, parent, opacity} = options

    cssClass =    ["kdoverlay"]
    cssClass.push  "animated"         if animated
    cssClass.push  "transparent"      if transparent
    options.cssClass = cssClass.join " "
    super

    isRemovable ?= yes

    if color
      @$().css
        backgroundColor: color
        opacity: opacity ? 0.5

    if "string" is typeof parent
      @$().appendTo $(parent)
    else if parent instanceof KDView
      @$().appendTo parent.$()

    if animated
      @utils.defer =>
        @$().addClass "in"
      @utils.wait 300, =>
        @emit "OverlayAdded", @
    else
      @emit "OverlayAdded", @

    if isRemovable
      @$().on "click.overlay", @removeOverlay.bind @

  removeOverlay: ->

    @emit "OverlayWillBeRemoved"
    callback = =>
      @$().off "click.overlay"
      @destroy()
      @emit "OverlayRemoved", @

    if @$().hasClass "animated"
      @$().removeClass "in"
      @utils.wait 300, =>
        callback()
    else
      callback()
