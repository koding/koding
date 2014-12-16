class IDE.StatusBarMenuItem extends JContextMenuItem

  viewAppended:->
    data = @getData()

    return super()  unless data.type isnt 'customView'

    @updatePartial """
      <span class='name'>#{data.title}</span>
      <span class='shortcut'>#{data.shortcut}</span>
      """
