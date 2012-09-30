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
        else
          styles.push "color: #{terminal.definedColors[@textColor]}"
      if @backgroundColor?
        if @backgroundColor < 16
          classes.push "background#{COLOR_NAMES[@backgroundColor]}"
        else
          styles.push "background-color: #{terminal.definedColors[@backgroundColor]}"
      
      {
        class: classes.join(" ")
        style: styles.join("; ")
      }
  
  @DEFAULT_STYLE = new Style
