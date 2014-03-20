class LiveUpdateChecker extends KDObject

  healthCheck: (callback) ->
    {notificationController} = KD.singletons
    notificationController.off "NotificationHasArrived"
    notificationController.on "NotificationHasArrived", (notification) =>
      callback()  if notification?.event is "healthCheck"
    KD.remote.api.JSystemStatus.checkRealtimeUpdates callback