class IDE.ChatView extends KDTabView

  constructor: (options = {}, data)->

    options.cssClass = 'chat-view'

    super options, data

    @addPane @settingsPane = new IDE.ChatSettingsPane
    @addPane @settingsPane = new IDE.ChatSettingsPane


  show: ->





