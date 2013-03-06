class MonitorController extends KDController

  constructor:(options,data)->
    super options,data

    @serviceList =[
      'kite-applications'
      'kite-webterm'
      'kite-databases'
      'kite-sharedHosting'
      'koding-social-*'
    ]

    @serviceToMethod =
      'kite-applications' : 'appKite'
      'kite-webterm'      : 'webtermKite'
      'kite-databases'    : 'databaseKite'
      'kite-sharedHosting': 'sharedHostingKite'
      'koding-social-*'   : 'socialWorker'

    @monitorData = {}
    @offlineServices = []


    @monitorPresence()

    @registerSingleton 'monitorController', @, no


  # SUBSCRIBE TO JOIN/LEAVE EVENTS

  monitorPresence:->
    @monitorHandler =
      join : =>
        @handleJoin arguments
      leave : =>
        @handleLeave arguments

    KD.remote.monitorPresence @monitorHandler

  parseRoutingKey:(routingKey)->
    data = {}
    items = routingKey.split('.')
    while items.length
      tuple           = items.splice 0, 2
      if /\|/.test tuple[1]
        tupleContent  = tuple[1].split '|'
        tuple[1]      =
          name        : tupleContent[0] or null
          location    : tupleContent[1] or null
          pid         : tupleContent[0]?.match(/\d+$/g)?[0]
      data[tuple[0]]  = tuple[1]
    data


  # JOIN/LEAVE HANDLERS

  handleJoin:(args)->
    # log 'Join.', @parseRoutingKey args[0]
    @addMonitorData @parseRoutingKey args[0]
    @checkForServices()

  handleLeave:(args)->
    # log 'Leave: ', @parseRoutingKey args[0]
    @removeMonitorData @parseRoutingKey args[0]
    @checkForServices()


  # GETTER/SETTER

  addMonitorData:(data)->
    @monitorData[data.serviceGenericName]=data

  removeMonitorData:(data)->
    delete @monitorData[data.serviceGenericName]

  getMonitorData:(key=null)->
    unless key
      @monitorData
    else
      if @monitorData[key]
          @monitorData[key]
      else
        if /\*/.test key
          @socialWorkers = 0
          for item of @monitorData
            if item.indexOf(key.replace('*','')) isnt -1
              @socialWorkers++
              socialWorker = @monitorData[item]
          socialWorker?.count = @socialWorkers
          return socialWorker

  getOnlineServices:->
    services = []
    for key in @serviceList
      serviceData = @checkForService key
      if serviceData
        services.push serviceData
        if @offlineServices.indexOf(key) isnt -1 or serviceData.count

          @emit 'ServiceWentOnline', key, serviceData
          @[@serviceToMethod[key]+'Join']?(serviceData)

          for service,i in @offlineServices
            @offlineServices.splice(i,1) if service is key
      else
        @offlineServices.push key unless @offlineServices.indexOf(key) isnt -1
        if key.indexOf('*') isnt -1
          serviceData =
            count : @socialWorkers
        else
          serviceData = null

        @emit 'ServiceWentOffline', key, serviceData
        @[@serviceToMethod[key]+'Leave']?(serviceData)

    services

  getOfflineServices:->
    @getOnlineServices()
    @offlineServices


  # CHECKING METHODS

  checkForService:(serviceGenericName)->
    @getMonitorData(serviceGenericName) or no

  checkForServices:->
    serviceCount = @getOfflineServices().length
    if serviceCount is 0
      @emit 'AllServicesOnline'
    else
      if serviceCount is @serviceList.length
        @emit 'AllServicesOffline'
      else
        @emit 'SomeServicesOnline'



  # EVENT HANDLING METHODS

  appKiteJoin:()->
  appKiteLeave:()->

  webtermKiteJoin:()->
  webtermKiteLeave:()->

  sharedHostingKiteJoin:()->
  sharedHostingKiteLeave:()->

  databaseKiteJoin:()->
  databaseKiteLeave:()->

  socialWorkerJoin:()->
  socialWorkerLeave:()->

