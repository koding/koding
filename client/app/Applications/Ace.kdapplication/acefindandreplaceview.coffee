class AceFindAndReplaceView extends JView

  constructor: (options = {}, data) ->

    options.cssClass = "ace-find-replace-view"

    @mode           = null
    @isHidden       = yes
    @lastViewHeight = 0

    super options, data

    @findInput = new KDHitEnterInputView
      type         : "text"
      validate     :
        rules      :
          required : yes
      keyup        : @bindSpecialKeys()
      callback     : => @findNext()

    @findNextButton = new KDButtonView
      title        : "Find Next"
      callback     : => @findNext()

    @findPrevButton = new KDButtonView
      title        : "Find Prev"
      callback     : => @findPrev()

    @replaceInput = new KDHitEnterInputView
      type         : "text"
      cssClass     : "ace-replace-input"
      validate     :
        rules      :
          required : yes
      keyup        : @bindSpecialKeys()
      callback     : => @replace()

    @replaceButton = new KDButtonView
      title        : "Replace"
      cssClass     : "ace-replace-button clean-gray"
      callback     : => @replace()

    @replaceAllButton = new KDButtonView
      title        : "Replace All"
      cssClass     : "ace-replace-button clean-gray"
      callback     : => @replaceAll()

    @closeButton = new KDCustomHTMLView
      tagName      : "span"
      cssClass     : "close-icon"
      click        : => @close()

    @findInput.on "keyup", (e) =>
      @findNext() unless e.keyCode is 13

    @choices = new KDMultipleChoice
      cssClass     : "clean-gray editor-button control-button"
      labels       : ["case-sensitive", "whole-word", "regex"]
      multiple     : yes

  bindSpecialKeys: ->
    "esc"           : (e) => @close()
    "super+f"       : (e) =>
      e.preventDefault()
      @setViewHeight no
    "super+shift+f" : (e) =>
      e.preventDefault()
      @setViewHeight yes

  close: ->
    # @resizeAceEditor 0
    # @$().css top: 19
    @hide()
    @resizeAceEditor 0

  setViewHeight: (isReplaceMode) ->
    # height   = 32
    # @mode    = "find"

    # if isReplaceMode
    #   @mode  = "replace"
    #   height = 60

    # if @isHidden
    #   @show()
    #   @isHidden = no

    # @$().css { height }
    # @resizeAceEditor height
    # @findInput.setFocus()

    height = if isReplaceMode then 60 else 32
    @show()
    @$().css { height }
    @resizeAceEditor height
    @findInput.setFocus()

  resizeAceEditor: (height) ->
    {ace} = @getDelegate()
    ace.setHeight ace.getHeight() + @lastHeightTakenFromAce - height
    ace.editor.resize yes
    @lastHeightTakenFromAce = height

  lastHeightTakenFromAce: 0

  setTextIntoFindInput: (text) ->
    return if text.indexOf("\n") > 0
    @findInput.setValue text
    @findInput.focus()

  getSearchOptions: ->
    @selections   = @choices.getValue()

    caseSensitive : @selections.indexOf("case-sensitive") > -1
    wholeWord     : @selections.indexOf("whole-word") > -1
    regExp        : @selections.indexOf("regex") > -1
    backwards     : no

  findNext: -> @find_ "next"

  findPrev: -> @find_ "prev"

  find_: (direction) ->
    keyword = @findInput.getValue()
    return unless keyword
    methodName = if direction is "prev" then "findPrevious" else "find"
    @getDelegate().ace.editor[methodName] @findInput.getValue(), @getSearchOptions()
    @findInput.focus()

  replace:    -> @replace_ no

  replaceAll: -> @replace_ yes

  replace_: (doReplaceAll) ->
    findKeyword    = @findInput.getValue()
    replaceKeyword = @replaceInput.getValue()
    return unless findKeyword or replaceKeyword

    {editor}   = @getDelegate().ace
    methodName = if doReplaceAll then "replaceAll" else "replace"

    # editor.find findKeyword, @getSearchOptions() if not doReplaceAll
    editor[methodName] replaceKeyword

  pistachio: ->
    """
      <div class="ace-find-replace-settings">
        {{> @choices}}
      </div>
      <div class="ace-find-replace-inputs">
        {{> @findInput}}
        {{> @replaceInput}}
      </div>
      <div class="ace-find-replace-buttons">
        {{> @findNextButton}}
        {{> @findPrevButton}}
        {{> @replaceButton}}
        {{> @replaceAllButton}}
      </div>
      {{> @closeButton}}
    """