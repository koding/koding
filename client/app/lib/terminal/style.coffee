module.exports = class Style

  COLOR_NAMES = ['Black', 'Red', 'Green', 'Yellow',
                 'Blue', 'Magenta', 'Cyan', 'White',
                 'BrightBlack', 'BrightRed', 'BrightGreen', 'BrightYellow',
                 'BrightBlue', 'BrightMagenta', 'BrightCyan', 'BrightWhite']

  DECORS = ['bold', 'underlined', 'outlined', 'inverse']
  COLORS = ['textColor', 'backgroundColor']

  constructor: (options) ->

    options ?= {}

    for decor in DECORS
      this[decor] = options[decor] ? no
    for color in COLORS
      this[color] = options[color] ? null


  isDefault: ->

    return no  for decor in DECORS when this[decor]
    return no  for color in COLORS when this[color]

    return yes


  equals: (other) ->

    for attr in DECORS.concat COLORS
      return no  unless other[attr] is this[attr]

    return yes


  getAttributes: ->

    classes = []
    styles  = []

    for decor in DECORS
      classes.push decor  if this[decor]

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

    return {
      class: classes.join ' '
      style: styles.join '; '
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
