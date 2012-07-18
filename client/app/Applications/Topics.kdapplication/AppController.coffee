class Topics12345 extends AppController
  
  listItemClass = TopicsListItemView

  constructor:(options, data)->
    options = $.extend
      # view : if /localhost/.test(location.host) then new TopicsMainView cssClass : "content-page topics" else new TopicsComingSoon
      # view : new TopicsComingSoon
      view : new TopicsMainView(cssClass : "content-page topics")
    ,options
    super options,data
    @controllers = {}

  bringToFront:()->
    @propagateEvent (KDEventType : 'ApplicationWantsToBeShown', globalEvent : yes),
      options :
        name : 'Topics'
      data : @getView()

  initAndBringToFront:(options,callback)->
    @bringToFront()
    callback()

  createFeed:(view)->
    appManager.tell 'Feeder', 'createContentFeedController', {
      subItemClass          : listItemClass
      limitPerPage          : 20
      # feedMessage           :
      #   title                 : "Topics organize shared content on Koding. Tag items when you share, and follow topics to see content relevant to you in your activity feed."
      #   messageLocation       : 'Topics'
      help                  :
        subtitle            : "Learn About Topics"
        tooltip             :
          title             : "<p class=\"bigtwipsy\">Topic Tags organize content that users share on Koding. Follow the topics you are interested in and we'll include the tagged items in your activity feed.</p>"
          placement         : "above"
      filter                :
        everything          :
          title             : "All topics"
          dataSource        : (selector, options, callback)=>
            bongo.api.JTag.someWithRelationship selector, options, callback
        followed            :
          title             : "Followed"
          dataSource        : (selector, options, callback)=>
            callback 'Coming soon!'
        recommended         :
          title             : "Recommended"
          dataSource        : (selector, options, callback)=>
            callback 'Coming soon!'
      sort                  :
        'counts.followers'  :
          title             : "Most popular"
          direction         : -1
        'meta.modifiedAt'   :
          title             : "Latest activity"
          direction         : -1
        'counts.tagged'     :
          title             : "Most activity"
          direction         : -1
    }, (controller)=>
      view.addSubView controller.getView()

  loadView:(mainView)->
    mainView.createCommons()
    KD.whoami().fetchRole (err, role) =>
      if role is "super-admin"
        listItemClass = TopicsListItemViewEditable
      @createFeed mainView
    # mainView.on "AddATopicFormSubmitted",(formData)=> @addATopic formData

    @getSingleton('mainController').on "TopicItemEditLinkClicked", (topic)=>
      @updateTopic topic
  
  updateTopic:(topic)->
    log "Update this: ", topic
    controller = @
    modal = new KDModalViewWithForms
      title                       : "Update topic " + topic.title
      height                      : "auto"
      cssClass                    : "compose-message-modal"
      width                       : 500
      overlay                     : yes
      tabs                        :
        navigateable              : yes
        goToNextFormOnSubmit      : no
        forms                     : 
          update                  :
            title                 : "Update Topic Details"
            callback              : (formData) =>
              @emit "UpdateTopic"
              log "Update:: ", formData
              modal.modalTabs.forms.update.buttons.Update.hideLoader()
              modal.destroy()
            buttons               :
              Update              :
                style             : "modal-clean-gray"
                type              : "submit"
                loader            :
                  color           : "#444444"
                  diameter        : 12
              Delete              :
                style             : "modal-clean-red"
                loader            :
                  color           : "#ffffff"
                  diameter        : 16
                callback          : =>
                  topic.delete (err)=>
                    modal.modalTabs.forms.update.buttons.Delete.hideLoader()
                    modal.destroy()
                    unless err then @emit 'TopicIsDeleted'
                    else new KDNotificationView
                        type      : "mini"
                        cssClass  : "error editor"
                        title     : err.message or "Error, please try again later!"
            fields                :
              Title               :
                label             : "Title"
                itemClass         : KDInputView
                name              : "title"
                defaultValue      : topic.title
              Details             :
                label             : "Details"
                type              : "textarea"
                itemClass         : KDInputView
                name              : "details"
                defaultValue      : topic.body or ""

  fetchFeedForHomePage:(callback)->
    options =
      limit     : 6
      skip      : 0
      sort      :
        "counts.followers": -1
        # "meta.modifiedAt": -1
    selector = {}
    bongo.api.JTag.someWithRelationship selector, options, callback

  # addATopic:(formData)->
  #   # log formData,"controller"
  #   bongo.api.JTag.create formData, (err, tag)->
  #     if err
  #       warn err,"there was an error creating topic!"
  #     else
  #       log tag,"created topic #{tag.title}"

  createContentDisplay:(tag,doShow = yes)->
    @showContentDisplay tag

  showContentDisplay:(content)->
    contentDisplayController = @getSingleton "contentDisplayController"
    controller = new ContentDisplayControllerTopic null, content
    contentDisplay = controller.getView()
    contentDisplayController.propagateEvent KDEventType : "ContentDisplayWantsToBeShown",contentDisplay

  fetchTopics:({inputValue, blacklist}, callback)->

    bongo.api.JTag.byRelevance inputValue, {blacklist}, (err, tags)->
      unless err
        callback? tags
      else
        warn "there was an error fetching topics"