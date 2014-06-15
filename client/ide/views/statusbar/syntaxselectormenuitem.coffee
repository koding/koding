class IDE.SyntaxSelectorMenuItem extends KDView

  constructor: (options = {}, data) ->

    options.cssClass  = 'syntax-selector'

    super options, data

    @addSubView @label  = new KDCustomHTMLView
      tagName           : 'span'
      partial           : 'Syntax'

    @addSubView @select = new KDSelectBox
      selectOptions     : IDE.settings.editor.getSyntaxOptions()
      callback          : (value) => @emit 'SelectionMade', value
