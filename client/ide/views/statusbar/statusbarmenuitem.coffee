class IDE.StatusBarMenuItem extends JContextMenuItem

  viewAppended:->
    title = this.getData().title

    if not title
      return # because you are a custom view

    # $ is used as the separator to split title into spans
    # given title should be formatted as name$shortcut
    title = this.getData().title.split('$')
    @updatePartial """
      <span class='name'>#{title[0]}</span>
      <span class='shortcut'>#{title[1]}</span>
      """
