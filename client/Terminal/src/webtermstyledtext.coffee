class WebTerm.StyledText
  COLOR_NAMES = ["Black", "Red", "Green", "Yellow", "Blue", "Magenta", "Cyan", "White", "BrightBlack", "BrightRed", "BrightGreen", "BrightYellow", "BrightBlue", "BrightMagenta", "BrightCyan", "BrightWhite"]

  constructor: (text, style) ->
    @text = text
    @style = style
    @spanForced = false
    @node = null

  getNode: ->
    if not @node?
      if not @style.isDefault() or @spanForced
        @node = $(document.createElement("span"))
        @node.text @text
        @updateNode()
      else
        @node = document.createTextNode @text
    @node

  updateNode: ->
    @node.attr @style.getAttributes()

  class Style
    constructor: ->
      @bold = false
      @underlined = false
      @outlined = false
      @inverse = false
      @textColor = null
      @backgroundColor = null

    isDefault: ->
      not @bold and not @underlined and not @inverse and @textColor is null and @backgroundColor is null

    equals: (other) ->
      @bold is other.bold and @underlined is other.underlined and @inverse is other.inverse and @textColor is other.textColor and @backgroundColor is other.backgroundColor

    getAttributes: ->
      classes = []
      styles = []

      classes.push "bold" if @bold
      classes.push "underlined" if @underlined
      classes.push "outlined" if @outlined
      classes.push "inverse" if @inverse
      if @textColor?
        if @textColor < 16
          classes.push "text#{COLOR_NAMES[@textColor]}"
        else if @textColor < 232
          styles.push "color: #{@getColor(@textColor - 16)}"
        else if @textColor < 256
          styles.push "color: #{@getGrey(@textColor - 232)}"
      if @backgroundColor?
        if @backgroundColor < 16
          classes.push "background#{COLOR_NAMES[@backgroundColor]}"
        else if @backgroundColor < 232
          styles.push "background-color: #{@getColor(@backgroundColor - 16)}"
        else if @backgroundColor < 256
          styles.push "background-color: #{@getGrey(@backgroundColor - 232)}"

      {
        class: classes.join(" ")
        style: styles.join("; ")
      }

    getColor: (index) ->
      rIndex = Math.floor(index / 6 / 6) % 6
      gIndex = Math.floor(index / 6) % 6
      bIndex = index % 6
      r = if rIndex is 0 then 0 else rIndex * 40 + 55
      g = if gIndex is 0 then 0 else gIndex * 40 + 55
      b = if bIndex is 0 then 0 else bIndex * 40 + 55
      return "rgb(#{r}, #{g}, #{b})"

    getGrey: (index) ->
      l = index * 10 + 8
      return "rgb(#{l}, #{l}, #{l})"

  @DEFAULT_STYLE = new Style
