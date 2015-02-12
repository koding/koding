class ColorSelection extends KDCustomHTMLView
  constructor:(options={})->
    options.cssClass       = "environments-cs-container"
    options.instant       ?= yes
    options.colors         = [
      '#a2a2a2'
      '#ffa800'
      '#e13986'
      '#39bce1'
      '#0018ff'
      '#e24d45'
      '#34b700'
      '#a861ff' ]
    super options

  createColors : ->
    colorBoxes = []

    for color in @getOption "colors"

      @addSubView colorBox = new KDCustomHTMLView
        cssClass    : "environments-cs-color"
        color       : color
        attributes  :
          style     : "background-color : #{color}"
        click : ->
          @parent.options.selectedColor  = @getOption "color"
          @parent.emit "ColorChanged", @parent.getOption "selectedColor"

          box.unsetClass "selected" for box in colorBoxes
          @setClass      "selected"

      colorBoxes.push colorBox
      colorBox.setClass "selected" if color is @getOption "selectedColor"

  viewAppended : ->
    @createColors()