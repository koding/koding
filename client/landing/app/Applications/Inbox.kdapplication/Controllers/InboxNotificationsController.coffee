class InboxNotificationController extends KDListViewController
  
  constructor:->
    super
    @selectedMessages = {}
  
  loadNotifications:->
    #{currentDelegate} = KD.getSingleton('mainController').getVisitor()
    
    # currentDelegate.fetchNotificationsTimeline {}, {
    #   options:
    #     limit: 8
    #     sort:
    #       timestamp: -1
    #   targetOptions: 
    #     query:
    #       type:
    #         $exists: yes
    #         $nin: ['CRepliesActivity','CFollowBucket']
    # }, (err, notifications)->
    #   log (note for note in notifications)
    #   
