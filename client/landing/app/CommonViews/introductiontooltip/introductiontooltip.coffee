class IntroductionTooltip extends KDObject

  constructor: (options = {}, data) ->

    super options, data

    {tooltipView, parentView} = @getOptions()
    data = @getData()

    tooltipView.addSubView @closeButton = new KDCustomHTMLView
      tagName  : "span"
      cssClass : "close-icon"
      click    : => @close no, no

    if data.visibility is "stepByStep"
      buttonTitle = if data.nextItem then "Next" else "Finish"
      tooltipView.addSubView @navButton = new KDButtonView
        title    : buttonTitle
        cssClass : "editor-button"
        callback : =>
          @close yes, yes
          delayForNext = @getData().delayForNext
          if delayForNext > 0
            @utils.wait delayForNext, =>
              @emit "IntroductionTooltipNavigated", data
          else
            @emit "IntroductionTooltipNavigated", data

    parentView.setTooltip
      view      : tooltipView
      cssClass  : "introduction-tooltip"
      sticky    : yes
      placement : data.placement

    @utils.defer =>
      parentView.tooltip.show()

  close: (hasNext, processCallback = yes) ->
    if processCallback
      data     = @getData()
      callback = Encoder.htmlDecode(data.callback)
      eval callback if data.callback
    @emit "IntroductionTooltipClosed", hasNext
    @destroy()
