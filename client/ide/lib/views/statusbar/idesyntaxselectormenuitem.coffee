kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
KDSelectBox = kd.SelectBox
KDView = kd.View
editorSettings = require '../../workspace/panes/settings/editorsettings'


module.exports = class IDESyntaxSelectorMenuItem extends KDView

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
