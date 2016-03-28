$ = require 'jquery'
StyledText = require './styledtext'


module.exports = class ScreenBuffer
  constructor: (@terminal) ->
    @lineContents = []
    @lineDivs = []
    @lineDivOffset = 0
    @scrollbackLimit = 1000
    @linesToUpdate = []
    @lastScreenClearLineCount = 1
    @scrollingRegion = [0, @terminal.sizeY - 1]

  toLineIndex: (y) ->
    @lineContents.length - Math.min(@terminal.sizeY, @lineContents.length) + y

  getLineContent: (index) ->
    @lineContents[index] ? new ContentArray

  setLineContent: (index, content) ->
    return if content.elements.length is 0 and @lineContents.length <= index and index < @terminal.sizeY
    while @lineContents.length < index
      @lineContents.push new ContentArray
    @lineContents[index] = content
    @linesToUpdate.push index unless index in @linesToUpdate

  isFullScrollingRegion: ->
    @scrollingRegion[0] is 0 and @scrollingRegion[1] is @terminal.sizeY - 1

  scroll: (amount) ->
    if amount > 0 and @isFullScrollingRegion()
      @addLineToUpdate @terminal.cursor.y
      @setLineContent @lineContents.length - 1 + amount, new ContentArray
    else
      direction = if amount > 0 then 1 else -1
      startIndex = if amount > 0 then 0 else 1
      for y in [@scrollingRegion[startIndex]..@scrollingRegion[1 - startIndex]] by direction
        newContent = if y + amount >= @scrollingRegion[0] and y + amount <= @scrollingRegion[1]
          @getLineContent @toLineIndex(y + amount)
        else
          new ContentArray
        @setLineContent @toLineIndex(y), newContent


  clear: (force) ->
    if force or not @isFullScrollingRegion or @lastScreenClearLineCount is @lineContents.length
      for y in [0...@terminal.sizeY]
        @setLineContent @toLineIndex(y), new ContentArray
    else
      @scroll @terminal.sizeY
      @lastScreenClearLineCount = @lineContents.length

  addLineToUpdate: (index) ->
    absoluteIndex = @toLineIndex index
    @linesToUpdate.push absoluteIndex unless absoluteIndex in @linesToUpdate

  flush: ->
    @linesToUpdate.sort (a, b) -> a - b
    maxLineIndex = @linesToUpdate[@linesToUpdate.length - 1]

    linesToAdd = maxLineIndex - @lineDivOffset - @lineDivs.length + 1
    if linesToAdd > 0
      scrolledToBottom = @terminal.isScrolledToBottom() or @terminal.container.queue().length isnt 0
      newDivs = []
      for i in [0...linesToAdd]
        div = global.document.createElement('div')
        $(div).text '\xA0'
        newDivs.push div
        @lineDivs.push div
      @terminal.outputbox.append newDivs

      linesToDelete = @lineDivs.length - @scrollbackLimit
      if linesToDelete > 0
        scrollOffset = @terminal.container.prop('scrollHeight') - @terminal.container.scrollTop()
        $(@lineDivs.slice(0, linesToDelete)).remove()
        @lineDivs = @lineDivs.slice linesToDelete
        @lineDivOffset += linesToDelete
        @terminal.container.scrollTop(@terminal.container.prop('scrollHeight') - scrollOffset)

      @terminal.scrollToBottom() if scrolledToBottom

    for index in @linesToUpdate
      content = @getLineContent index
      content = @terminal.cursor.addCursorElement content if index is @toLineIndex(@terminal.cursor.y)

      div = $(@lineDivs[index - @lineDivOffset])
      div.empty()
      div.append content.getNodes()
      div.text '\xA0' if content.getNodes().length is 0

    @linesToUpdate = []

    # flushedCallback doesnt have to be set.
    @terminal.flushedCallback?()

  class ContentArray
    constructor: ->
      @elements = []
      @merge = true

    push: (element) ->
      if @merge and @elements.length > 0 and @elements[@elements.length - 1].style.equals element.style
        @elements[@elements.length - 1].text += element.text
      else
        @elements.push element

    pushAll: (content) ->
      return if content.elements.length is 0
      @push content.elements[0] # possible merge
      @elements = @elements.concat content.elements[1..-1]

    length: ->
      @elements.length

    get: (index) ->
      @elements[index]

    getNodes: ->
      element.getNode() for element in @elements

    substring: (beginIndex, endIndex) ->
      content = new ContentArray
      offset = 0
      length = 0

      for styledText in @elements
        text = if endIndex?
          styledText.text.substring(beginIndex - offset, endIndex - offset)
        else
          styledText.text.substring(beginIndex - offset)
        if text.length > 0
          content.push new StyledText(text, styledText.style)
          length += text.length
        offset += styledText.text.length

      missing = (endIndex - beginIndex) - length
      if missing > 0
        text = ''
        text += '\xA0' for [0...missing]
        content.push new StyledText(text, StyledText.DEFAULT_STYLE)

      content
