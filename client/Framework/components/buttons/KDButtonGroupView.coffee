class KDButtonGroupView extends KDView

  constructor:(options = {},data)->

    {cssClass} = options
    cssClass   = if cssClass then " #{cssClass}" else ""
    options.cssClass   = "kdbuttongroup#{cssClass}"
    options.buttons  or= {}

    super options,data
    @buttons = {}
    @createButtons options.buttons

  createButtons:(allButtonOptions)->

    for buttonTitle, buttonOptions of allButtonOptions
      buttonClass = buttonOptions.buttonClass or KDButtonView
      buttonOptions.title = buttonTitle
      buttonOptions.style = ""
      @addSubView @buttons[buttonTitle] = new buttonClass buttonOptions
      @listenTo
        KDEventTypes       : "click"
        listenedToInstance : @buttons[buttonTitle]
        callback           : (pubInst, event)=>
          @buttonReceivedClick pubInst, event

  buttonReceivedClick:(button, event)->
    for title, otherButton of @buttons
      otherButton.unsetClass "active"
    button.setClass "active"



