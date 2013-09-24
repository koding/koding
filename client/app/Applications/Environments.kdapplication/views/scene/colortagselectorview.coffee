class ColorSelection extends KDCustomHTMLView
  constructor:(options={})->
    options.cssClass = 'environments-cs-container'
    options.instant ?= yes
    options.colors   = [
      '#a2a2a2'
      '#ffa800'
      '#e13986'
      '#39bce1'
      '#0018ff'
      '#e24d45'
      '#34b700'
      '#a861ff' ]
    super options

    @selectedColor = '#a2a2a2'

  createColors : ->
    for color in @getOption "colors"

      @addSubView new KDCustomHTMLView
        cssClass    : "environments-cs-color"
        color       : color
        attributes  :
          style     : "background-color : #{color}"
        click : ->
          @selectedColor  = @getOption "color"
          @emit "colorChanged", @selectedColor

  viewAppended : ->
    @createColors()
    log @selectedColor