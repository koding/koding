class StatusLEDView extends KDView

  constructor:(options,data)->
    super options,data

    @setClass 'status-leds'

    @ledList = new KDListView
      itemClass : StatusLEDItemView

    monitorController = @getSingleton 'monitorController'

    monitorController.on 'ServiceWentOnline', (key,serviceData)=>
      for item in @ledList.items
        if item.getData() is key
          # log key, 'went on'
          item.setOnline()

    monitorController.on 'ServiceWentOffline', (key,serviceData)=>
      for item in @ledList.items
        if item.getData() is key
          # log key, 'went off'
          item.setOffline()

    for service in monitorController.serviceList
      @ledList.addItem service

    @on 'click', =>
      monitorController.monitorPresence()

  viewAppended:->
    super
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
    {{>@ledList}}
    """

class StatusLEDItemView extends KDListItemView
  keyToName =
      'kite-applications'  : 'Applications'
      'kite-webterm'       : 'Terminal'
      'kite-databases'     : 'Databases'
      'kite-sharedHosting' : 'Hosting'
      'koding-social-*'    : 'Social'

  constructor:(options={},data)->
    options.tooltip =
      title         : 'Service'
      direction     : 'center'
      placement     : 'bottom'

    super options,data
    @setClass 'led'

    #initial color
    @setOnline()

  setOnline:->
    @getOptions().tooltip.title = keyToName[@getData()]+' online'
    @unsetClass 'red'
    @unsetClass 'yellow'
    @unsetClass 'off'
    @setClass 'green'

  setOffline:->
    log "service #{@getData()} set offline"
    @getOptions().tooltip.title = keyToName[@getData()]+' offline'
    @unsetClass 'yellow'
    @unsetClass 'off'
    @unsetClass 'green'
    @setClass 'red'
  setWaiting:->
    @getOptions().tooltip.title = keyToName[@getData()]+' under heavy load. Please wait.'
    @unsetClass 'red'
    @unsetClass 'green'
    @unsetClass 'off'
    @setClass 'yellow'

  setOff:->
    @getOptions().tooltip.title = 'You are not connected to Koding.'
    @unsetClass 'yellow'
    @unsetClass 'green'
    @unsetClass 'red'
    @setClass 'off'

  viewAppended:->
    super
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
    """