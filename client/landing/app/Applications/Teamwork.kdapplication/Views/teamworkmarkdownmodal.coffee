class TeamworkMarkdownModal extends KDModalView

  constructor: (options, data) ->

    options.title    = "README"
    options.cssClass = "has-markdown teamwork-markdown"
    options.overlay  = yes
    options.width    = 630

    super options, data

    @bindTransitionEnd()

    @once "transitionend", =>
      @utils.wait 133, =>
        KDModalView::destroy.call this
        @getOptions().targetEl.setCss "opacity", 1

  destroy: ->
    @setClass "scale"
    {targetEl} = @getOptions()
    targetEl.setClass "opacity"

    top     = targetEl.getY()
    left    = targetEl.getX()
    width   = @getWidth()
    height  = @getHeight()

    newTop  = top  + 12 - (height / 2) # 11 is scaled width
    newLeft = left - (width / 2)

    @setStyle
      left   : newLeft
      top    : newTop
