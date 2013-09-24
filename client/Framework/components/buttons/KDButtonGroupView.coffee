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

    for own buttonTitle, buttonOptions of allButtonOptions
      buttonClass = buttonOptions.buttonClass or KDButtonView
      buttonOptions.title = buttonTitle
      buttonOptions.style = ""
      @addSubView @buttons[buttonTitle] = new buttonClass buttonOptions
      @buttons[buttonTitle].on "click", (event)=>
        @buttonReceivedClick @buttons[buttonTitle], event

  buttonReceivedClick:(button, event)->
    for own title, otherButton of @buttons
      otherButton.unsetClass "toggle"
    button.setClass "toggle"



