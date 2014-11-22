class IDE.ChatMessagePane extends PrivateMessagePane

  constructor: (options = {}, data)->

    options.cssClass = 'privatemessage'

    super options, data

    @addSubView @back = new KDButtonView
      title    : 'settings'
      cssClass : 'solid green mini'
      callback : => @getDelegate().showSettingsPane()

    @back.setStyle
      position : 'absolute'
      top      : '16px'
      right    : '16px'
      'z-index': 12
