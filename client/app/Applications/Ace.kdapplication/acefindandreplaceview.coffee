class AceFindAndReplaceView extends JView

  constructor: (options = {}, data) ->

    options.cssClass = "ace-find-and-replace-view"

    @mode = null

    super options, data

    @findInput    = new KDHitEnterInputView
      type         : "text"
      cssClass     : "ace-find-replace-input"
      validate     :
        rules      :
          required : yes
      placeholder  : "Find:"
      callback     : (keyword) => @find keyword

    @replaceInput = new KDHitEnterInputView
      type         : "text"
      cssClass     : "ace-find-replace-input"
      validate     :
        rules      :
          required : yes
      placeholder  : "Replace:"
      callback     : (keyword) => @replace keyword

    @closeButton = new KDCustomHTMLView
      tagName      : 'span'
      cssClass     : 'close-icon'
      click        : => @$().css top: 0

  find: (keyword) ->
    return unless keyword
    return if @mode is 'replace' then @replace()
    @getDelegate().ace.editor.find keyword

  replace: ->
    findKeyword    = @findInput.getValue()
    replaceKeyword = @replaceInput.getValue()
    return unless findKeyword or replaceKeyword
    {editor} = @getDelegate().ace
    editor.find    findKeyword
    editor.replace replaceKeyword

  pistachio: ->
    """
      {{> @findInput}}
      {{> @replaceInput}}
      {{> @closeButton}}
    """