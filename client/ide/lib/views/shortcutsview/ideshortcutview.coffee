kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
JView = require 'app/jview'
module.exports = class IDEShortcutView extends JView

  constructor: (options = {}, data) ->

    options.cssClass = 'key-map'

    super options, data

    {@description, @shortcut} = @getData()

    @wrapper = new KDCustomHTMLView cssClass: 'keys'
    keys     = @shortcut.split '-'

    for key in keys
      @wrapper.addSubView new KDCustomHTMLView cssClass: 'key', partial: key

  pistachio: ->
    """
      <div class="description">
        #{@description}
      </div>
      {{> @wrapper}}
    """
