module.exports = class ControlCodeReader

  constructor: (@terminal, @handler, @nextReader) ->
    @data = ''
    @pos = 0
    @controlCodeOffset = null
    @regexp = new RegExp Object.keys(@handler.map).join('|')

  skip: (length) ->
    @pos += length

  readChar: ->
    return null if @pos >= @data.length
    c = @data.charAt @pos
    @pos += 1
    c

  readRegexp: (regexp) ->
    result = @data.substring(@pos).match(regexp)
    return null if not result?
    @pos += result[0].length
    result

  readUntil: (regexp) ->
    endPos = @data.substring(@pos).search regexp
    return null if endPos is -1
    string = @data.substring @pos, @pos + endPos
    @pos += endPos
    string

  addData: (newData) ->
    @data += newData

  process: ->
    return false if not @nextReader.process()
    return true if @data.length is 0

    if @controlCodeOffset?
      @controlCodeIncomplete = false
      @handler this
      if @controlCodeIncomplete
        @pos = @controlCodeOffset
        true
      else
        @controlCodeOffset = null
        false
    else
      if (text = @readUntil @regexp)?
        @nextReader.addData text
        @nextReader.process()
        @controlCodeOffset = @pos
        false
      else
        @nextReader.addData @data.substring(@pos)
        @data = ''
        @pos = 0
        @nextReader.process()

  incompleteControlCode: ->
    @controlCodeIncomplete = true

  unsupportedControlCode: ->
    # warn "Unsupported control code: " + @terminal.inspectString(@data.substring(@controlCodeOffset, @pos))
