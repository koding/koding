class LiveUpdateChecker extends KDObject

  constructor: (options, data) ->
    super options, data
    {notificationController} = KD.singletons
    notificationController.on "NotificationHasArrived", (notification) =>
      @emit "healthCheckReceived"  if notification?.event is "healthCheck"

  healthCheck: (callback) ->
    @once "healthCheckReceived", callback
    KD.remote.api.JSystemStatus.checkRealtimeUpdates callback