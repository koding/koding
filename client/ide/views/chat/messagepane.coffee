class IDE.ChatMessagePane extends KDTabPaneView

  constructor: (options = {}, data)->

    options.cssClass = 'messages'

    super options, data

