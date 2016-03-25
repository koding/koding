kd = require 'kd'
JContextMenuItem = kd.JContextMenuItem
module.exports = class IDEStatusBarMenuItem extends JContextMenuItem

  viewAppended: ->

    { title, type, shortcut } = @getData()

    return super()  unless type isnt 'customView'

    @updatePartial """
      <span class='name'>#{title}</span>
      <span class='shortcut'>#{shortcut ? ''}</span>
      """
