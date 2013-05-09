class IntroductionTooltip extends KDObject

  constructor: (options = {}, data) ->

    super options, data

    {tooltipView, parentView} = @getOptions()
    data = @getData()

    tooltipView.addSubView @closeButton = new KDCustomHTMLView
      tagName  : "span"
      cssClass : "close-icon"
      click    : => @close()

    if data.visibility is "stepByStep"
      buttonTitle = if data.nextItem then "Next" else "Finish"
      tooltipView.addSubView @navButton = new KDButtonView
        title    : buttonTitle
        cssClass : "editor-button"
        callback : =>
          @close yes
          @emit "IntorductionTooltipNavigated", data

    parentView.setTooltip
      view      : tooltipView
      cssClass  : "introduction-tooltip"
      sticky    : yes
      placement : data.placement

    @utils.defer =>
      parentView.tooltip.show()

  close: (hasNext) ->
    @emit "IntroductionTooltipClosed", hasNext
    @destroy()
