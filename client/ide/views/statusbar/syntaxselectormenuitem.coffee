editorSettings = require '../../workspace/panes/settings/editorSettings'


class SyntaxSelectorMenuItem extends KDView

  constructor: (options = {}, data) ->

    options.cssClass  = 'syntax-selector'

    super options, data

    @addSubView @label  = new KDCustomHTMLView
      tagName           : 'span'
      partial           : 'Syntax'

    @addSubView @select = new KDSelectBox
      cssClass          : 'dark'
      selectOptions     : editorSettings.getSyntaxOptions()
      callback          : (value) => @emit 'SelectionMade', value


module.exports = SyntaxSelectorMenuItem
