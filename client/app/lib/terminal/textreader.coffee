module.exports = class TextReader

  constructor: (@terminal) ->
    @data = ''

  addData: (newData) ->
    @data += newData

  process: ->
    return true if @data.length is 0
    while @terminal.cursor.x + @data.length > @terminal.sizeX # line wrapping
      remaining = @terminal.sizeX - @terminal.cursor.x
      @terminal.writeText @data.substring(0, remaining)
      @terminal.lineFeed()
      @terminal.cursor.moveTo 0, @terminal.cursor.y
      @data = @data.substring remaining
    @terminal.writeText @data
    @terminal.cursor.move @data.length, 0
    @data = ''
    true
