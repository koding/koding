class BookTopics extends KDView

  viewAppended:->

    @addSubView loader = new KDLoaderView
      size          :
        width       : 60
      loaderOptions :
        color       : "#666666"
        shape       : "spiral"
        diameter    : 60
        density     : 60
        range       : 0.6
        speed       : 2
        FPS         : 25

    @utils.wait -> loader.show()

    appManager.tell "Topics", "fetchSomeTopics",
      limit : 20
    , (err, topics)=>
      loader.hide()
      if err then warn err
      else
        for topic in topics
          @addSubView topicLink = new TagLinkView null, topic
          topicLink.registerListener
            KDEventTypes : "click"
            listener     : @
            callback     : =>
              @getDelegate().$().css left : -1349
              @utils.wait 4000, =>
                @getDelegate().$().css left : -700
