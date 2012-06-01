class Editor_BottomBar_Info extends Editor_BottomBar_Section
  constructor: (options = {}, data) ->
    options.cssClass = "caret-position"
    options.partial = "<span>1</span>:<span>1</span>"
    super options, data
    @$line = @$('span:first-child')
    @$col  = @$('span:last-child')

  setRow: (lineNumber = 0) ->
    @$line.text ++lineNumber

  setColumn: (columnNumber = 0) ->
    @$col.text ++columnNumber
