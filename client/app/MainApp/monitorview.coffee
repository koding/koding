class StatusLEDView extends KDView

  constructor:(options,data)->
    super options,data

    @setClass 'status-leds'

    @allServicesOnline = no

    @ledList = new KDListView
      itemClass : StatusLEDItemView

    @ledList.hide() unless KD.checkFlag "super-admin"

    @ledLabel = new KDView
      cssClass : 'status-label'
      partial  : 'System Status'
      click    :=>
        @ledList.show()

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

    monitorController.on 'AllServicesOnline', =>
      # @ledList.hide()
      @allServicesOnline = yes

    monitorController.on 'AllServicesOffline', =>
      @show()
      # @ledList.show()
      @allServicesOnline = no
    monitorController.on 'SomeServicesOnline', =>
      @show()
      # @ledList.show()
      @allServicesOnline = no

    for service in monitorController.serviceList
      @ledList.addItem service

  hideIfAllServicesOnline:->
    @hide() if @allServicesOnline

  hide:->
    @utils.wait 500, =>
      @setClass 'fadeout'

    # super

  show:->
    @unsetClass 'fadeout'
    # super

  viewAppended:->
    super
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
    {{> @ledList}}
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
      # selector      : 'div.led'
      offset        :
        left        : -10
        top         : 0

    super options,data
    @setClass 'led-wrapper'

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

  show:->
    @unsetClass 'fadeout'
  hide:->
    @setClass 'fadeout'

  pistachio:->
    """
    <div class='led'></div>
    """