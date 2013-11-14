class TeamworkMarkdownModal extends KDModalView

  constructor: (options = {}, data) ->

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

    @setStyle
      left   : targetEl.getX() - (@getWidth()  / 2)
      top    : targetEl.getY() - (@getHeight() / 2) + 12 # 12 is scaled width
