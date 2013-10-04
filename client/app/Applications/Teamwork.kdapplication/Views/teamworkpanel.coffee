class TeamworkPanel extends CollaborativePanel

  showHintModal: ->
    workspace = @getDelegate()
    if workspace.markdownContent
      workspace.getDelegate().showMarkdownModal()
    else
      Panel::showHintModal.call this
