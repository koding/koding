class MonitorController extends KDController

  constructor:(options,data)->
    super options,data

    @serviceList =[
      'kite-applications'
      'kite-webterm'
      'kite-databases'
      'kite-sharedHosting'
      'koding-social-*'
      # 'koding-social-arvidkah'
    ]

    @monitorData = {}
    @offlineServices = []


    @monitorPresence()

    @registerSingleton 'monitorController', @, no


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


  handleJoin:(args)->
    # log 'Join.', @parseRoutingKey args[0]
    @addMonitorData @parseRoutingKey args[0]
    @checkForServices()

  handleLeave:(args)->
    # log 'Leave: ', @parseRoutingKey args[0]
    @removeMonitorData @parseRoutingKey args[0]
    @checkForServices()

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
          socialWorker.count = @socialWorkers
          return socialWorker

  checkForService:(serviceGenericName)->
    @getMonitorData(serviceGenericName) or no

  getOnlineServices:->
    services = []
    for key in @serviceList
      serviceData = @checkForService key
      if serviceData
        services.push serviceData
        if @offlineServices.indexOf(key) isnt -1 or serviceData.count
          @emit 'ServiceWentOnline', key, serviceData
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

    services

  getOfflineServices:->
    @getOnlineServices()
    @offlineServices

  checkForServices:->
    @getOfflineServices()
