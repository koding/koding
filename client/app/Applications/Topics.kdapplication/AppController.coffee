class Topics12345 extends AppController

  constructor:(options, data)->
    options = $.extend
      # view : if /localhost/.test(location.host) then new TopicsMainView cssClass : "content-page topics" else new TopicsComingSoon
      # view : new TopicsComingSoon
      view : new TopicsMainView(cssClass : "content-page topics")
    ,options
    super options,data
    @listItemClass = TopicsListItemView
    @controllers = {}

  bringToFront:()->
    @propagateEvent (KDEventType : 'ApplicationWantsToBeShown', globalEvent : yes),
      options :
        name : 'Topics'
      data : @getView()

  createFeed:(view)->
    appManager.tell 'Feeder', 'createContentFeedController', {
      itemClass          : @listItemClass
      limitPerPage          : 20
      noItemFoundText       : "There is no topics."
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
          optional_title    : if @_searchValue then "<span class='optional_title'></span>" else null
          dataSource        : (selector, options, callback)=>
            if @_searchValue
              @setCurrentViewHeader "Searching for <strong>#{@_searchValue}</strong>..."
              KD.remote.api.JTag.byRelevance @_searchValue, options, callback
            else
              KD.remote.api.JTag.someWithRelationship selector, options, callback
        following           :
          title             : "Following"
          noItemFoundText   : "There is no topics that you follow."
          dataSource        : (selector, options, callback)=>
            KD.whoami().fetchTopics selector, options, (err, items)=>
              for item in items
                item.followee = true
              callback err, items
        # recommended         :
        #   title             : "Recommended"
        #   dataSource        : (selector, options, callback)=>
        #     callback 'Coming soon!'
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
      @feedController = controller
      view.addSubView @_lastSubview = controller.getView()
      controller.on "FeederListViewItemCountChanged", (count)=>
        if @_searchValue then @setCurrentViewHeader count
      @emit 'ready'

  loadView:(mainView, firstRun = yes)->

    if firstRun
      mainView.on "searchFilterChanged", (value) =>
        return if value is @_searchValue
        @_searchValue = value
        @_lastSubview.destroy?()
        @loadView mainView, no

      mainView.createCommons()

    KD.whoami().fetchRole? (err, role) =>
      if role is "super-admin"
        @listItemClass = TopicsListItemViewEditable
        if firstRun
          @getSingleton('mainController').on "TopicItemEditLinkClicked", (topicItem)=>
            @updateTopic topicItem

      @createFeed mainView
    # mainView.on "AddATopicFormSubmitted",(formData)=> @addATopic formData

  updateTopic:(topicItem)->
    topic = topicItem.data
    # log "Update this: ", topic
    controller = @
    modal = new KDModalViewWithForms
      title                       : "Update topic " + topic.title
      height                      : "auto"
      cssClass                    : "compose-message-modal"
      width                       : 500
      overlay                     : yes
      tabs                        :
        navigable              : yes
        goToNextFormOnSubmit      : no
        forms                     :
          update                  :
            title                 : "Update Topic Details"
            callback              : (formData) =>
              formData.slug = @utils.slugify formData.slug.trim().toLowerCase()
              topic.modify formData, (err)=>
                new KDNotificationView
                  title : if err then err.message else "Updated successfully"
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
                    new KDNotificationView
                      title : if err then err.message else "Deleted!"
                    topicItem.hide() unless err
            fields                :
              Title               :
                label             : "Title"
                itemClass         : KDInputView
                name              : "title"
                defaultValue      : topic.title
              Slug                :
                label             : "Slug"
                itemClass         : KDInputView
                name              : "slug"
                defaultValue      : topic.slug
              Details             :
                label             : "Details"
                type              : "textarea"
                itemClass         : KDInputView
                name              : "body"
                defaultValue      : topic.body or ""

  fetchSomeTopics:(options = {}, callback)->

    options.limit or= 6
    options.skip  or= 0
    options.sort  or= "counts.followers": -1
    selector        = options.selector
    delete options.selector if options.selector
    
    if selector
      KD.remote.api.JTag.byRelevance selector, options, callback
    else
      KD.remote.api.JTag.someWithRelationship {}, options, callback

  # addATopic:(formData)->
  #   # log formData,"controller"
  #   KD.remote.api.JTag.create formData, (err, tag)->
  #     if err
  #       warn err,"there was an error creating topic!"
  #     else
  #       log tag,"created topic #{tag.title}"

  setCurrentViewHeader:(count)->
    if typeof 1 isnt typeof count
      @getView().$(".activityhead span.optional_title").html count
      return no
    if count >= 20 then count = '20+'
    # return if count % 20 is 0 and count isnt 20
    # postfix = if count is 20 then '+' else ''
    count   = 'No' if count is 0
    result  = "#{count} result" + if count isnt 1 then 's' else ''
    title   = "#{result} found for <strong>#{@_searchValue}</strong>"
    @getView().$(".activityhead").html title

  showContentDisplay:(content, callback=->)->
    contentDisplayController = @getSingleton "contentDisplayController"
    controller = new ContentDisplayControllerTopic null, content
    contentDisplay = controller.getView()
    contentDisplayController.emit "ContentDisplayWantsToBeShown", contentDisplay
    callback contentDisplay

  fetchTopics:({inputValue, blacklist}, callback)->

    KD.remote.api.JTag.byRelevance inputValue, {blacklist}, (err, tags)->
      unless err
        callback? tags
      else
        warn "there was an error fetching topics"
