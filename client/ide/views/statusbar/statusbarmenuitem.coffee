class StatusBarMenuItem extends JContextMenuItem

  viewAppended:->
    { title, type, shortcut } = @getData()

    return super()  unless type isnt 'customView'

    @updatePartial """
      <span class='name'>#{title}</span>
      <span class='shortcut'>#{shortcut}</span>
      """


module.exports = StatusBarMenuItem
