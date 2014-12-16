class IDE.StatusBarMenuItem extends JContextMenuItem

  viewAppended:->
    title = this.getData().title
    shortcut = this.getData().shortcut

    @updatePartial """
      <span class='name'>#{title}</span>
      <span class='shortcut'>#{shortcut}</span>
      """
