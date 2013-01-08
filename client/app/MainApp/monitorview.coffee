class StatusLEDView extends KDView

  constructor:(options,data)->
    super options,data

    @setClass 'status-leds'

    @ledList = new KDListView
      itemClass : StatusLEDItemView

    monitorController = @getSingleton 'monitorController'

    monitorController.on 'ServiceWentOnline', (key,serviceData={})=>
      for item in @ledList.items
        if item.getData() is key
          item.setOnline()
          if serviceData.count
            item.setCount serviceData.count

    monitorController.on 'ServiceWentOffline', (key,serviceData={})=>
      for item in @ledList.items
        if item.getData() is key
          item.setOffline()
          if serviceData.count
            item.setCount serviceData.count

    for service in monitorController.serviceList
      @ledList.addItem service

    @on 'click', =>
      monitorController.monitorPresence()

    @utils.wait 4000, =>
      @setClass 'pulse'

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
      offset        :
        left        : -10
        top         : 0

    super options,data
    @setClass 'led'

    #initial color
    @setOff()
    @currentState = 'off'

    @count = 0

  updateTooltip:(title=@currentState)->
    if @getCount() > 0
      @getOptions().tooltip.title = keyToName[@getData()]+" #{title} <br/><span class='instance-count'>("+@getCount()+' instances running)</span>'
    else
      @getOptions().tooltip.title = keyToName[@getData()]+" #{title}"

  setCurrentState:(state)->
    @currentState = state

  setCount:(newCount)->
    @count = newCount
    @updateTooltip()

  getCount:->
    @count

  setOnline:->
    @updateTooltip 'online'
    @setCurrentState 'online'
    @unsetClass 'red'
    @unsetClass 'yellow'
    @unsetClass 'off'
    @setClass 'green'

  setOffline:->
    @updateTooltip 'offline'
    @setCurrentState 'offline'
    @unsetClass 'yellow'
    @unsetClass 'off'
    @unsetClass 'green'
    @setClass 'red'

  setWaiting:->
    @updateTooltip 'under heavy load. Please wait.'
    @setCurrentState 'under heavy load. Please wait.'
    @unsetClass 'red'
    @unsetClass 'green'
    @unsetClass 'off'
    @setClass 'yellow'

  setOff:->
    @updateTooltip 'not connected'
    @setCurrentState 'not connected'
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