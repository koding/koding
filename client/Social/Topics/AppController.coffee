class TopicsAppController extends AppController

  KD.registerAppClass this,
    name         : "Topics"
    route        : "/:name?/Topics"
    searchRoute  : "/Topics?q=:text:"
    hiddenHandle : yes

  constructor:(options = {}, data)->

    options.view    = new TopicsMainView
      cssClass      : "content-page topics"
    options.appInfo =
      name          : "Topics"

    super options, data

    @listItemClass = TopicsListItemView
    @controllers = {}

    @_searchValue = ""

    # @on "LazyLoadThresholdReached", => @feedController.loadFeed()

  createFeed:(view, loadFeed = no)->
    {JTag} = KD.remote.api

    KD.getSingleton("appManager").tell 'Feeder', 'createContentFeedController', {
      feedId                : 'topics.main'
      itemClass             : @listItemClass
      limitPerPage          : 20
      useHeaderNav          : yes
      delegate              : this
      noItemFoundText       : "There are no topics."
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
              JTag.byRelevance @_searchValue, options, callback
            else
              JTag.some selector, options, callback
          dataError         : ->
            log "Seems something broken:", arguments

        following           :
          loggedInOnly      : yes
          title             : "Following"
          noItemFoundText   : "There are no topics that you follow."
          dataSource        : (selector, options, callback)=>
            KD.whoami().fetchTopics selector, options, (err, items)=>
              ids = []
              for item in items
                item.followee = true
                ids.push item._id
              callback err, items
              callback null, null, ids  unless err
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
        'counts.post'       :
          title             : "Most activity"
          direction         : -1
    }, (controller)=>
      @feedController = controller
      view.addSubView @_lastSubview = controller.getView()
      controller.on "FeederListViewItemCountChanged", (count)=>
        if @_searchValue then @setCurrentViewHeader count
      controller.loadFeed() if loadFeed
      @emit 'ready'

      KD.mixpanel "Load topic list, success"


  loadView:(mainView, firstRun = yes, loadFeed = no)->
    if firstRun
      @on "searchFilterChanged", (value) =>
        return if value is @_searchValue
        @_searchValue = Encoder.XSSEncode value
        @_lastSubview.destroy?()
        @loadView mainView, no, yes

      mainView.createCommons()

    {permissions} = KD.config
    canModerateTags = "edit tags" in permissions || "delete tags" in permissions || "create synonym tags" in permissions
    if canModerateTags
      @listItemClass = TopicsListItemViewEditable
      if firstRun
        KD.getSingleton('mainController').on "TopicItemEditClicked", (topicItem)=>
          @updateTopic topicItem
        KD.getSingleton('mainController').on "TopicItemDeleteClicked", (topicItem)=>
          @deleteTopic topicItem
        KD.getSingleton('mainController').on "TopicItemSetParentClicked", (topicItem)=>
          @setSynonymTopic topicItem

    @createFeed mainView, loadFeed

  openTopic:(topic)->
    {entryPoint} = KD.config
    KD.getSingleton('router').handleRoute "/Topics/#{topic.slug}", {state:topic, entryPoint}

  deleteTopic:(topicItem)->
    topic = topicItem.getData()
    modal             = new KDModalView
      title           : "Delete Topic"
      content         : "<div class='modalformline'>Are you sure you want to delete this topic? (This will also delete all the child topics!)</div>"
      overlay         : yes
      buttons         :
        Delete        :
          style       : "modal-clean-red"
          loader      :
            color     : "#ffffff"
            diameter  : 16
          callback    : =>
            topic.delete (err)=>
              topicItem.followButton.hide()
              # modal.buttons.Delete.hideLoader()
              modal.destroy()
              new KDNotificationView
                title : if err then err.message else "Deleted!"
        Cancel        :
          style       : "modal-cancel"
          title       : "cancel"
          callback    : ->
            modal.destroy()

  setSynonymTopic:(topicItem) ->
    topic = topicItem.getData()
    {synonym: parent} = topic
    modal = new KDModalViewWithForms
      title                       : "Set Parent Topic for #{topic.title}"
      height                      : "auto"
      cssClass                    : "compose-message-modal"
      width                       : 779
      overlay                     : yes
      tabs                        :
        navigable                 : yes
        goToNextFormOnSubmit      : no
        forms                     :
          synonym                 :
            buttons               :
              Confirm             :
                style             : "modal-clean-green"
                type              : "submit"
                loader            :
                  color           : "#444444"
                  diameter        : 12
              Cancel              :
                style             : "modal-clean-gray"
                title             : "Cancel"
                callback          : ->
                  modal.destroy()
            fields                :
              Synonym             :
                label             : "Parent"
                type              : "hidden"
            callback              : (formData) =>
              showStatus = (status) =>
                modal.modalTabs.forms.synonym.buttons.Confirm.hideLoader()
                new KDNotificationView
                  title : status
              unless formData.synonyms?.length
                return showStatus "You must choose parent topic first"

              [synonym] = formData.synonyms
              options = if synonym.$suggest then {title: synonym.$suggest.trim()}
              else {id: synonym.id}

              topic.createSynonym options, (err) ->
                status = if err then err.message else "Parent Topic is set successfully"
                showStatus status
                topicItem.followButton.hide()
                modal.destroy()

    {fields, inputs} = modal.modalTabs.forms["synonym"]
    @synonymController = new TagAutoCompleteController
      form              : modal.modalTabs.forms["synonym"]
      width             : 300
      name              : "synonym"
      itemClass         : TagAutoCompleteItemView
      itemDataPath      : "title"
      selectedItemClass : TagAutoCompletedItemView
      submitValueAsText : yes
      selectedItemsLimit: 1
      dataSource : (args, callback) =>
        {inputValue} = args
        KD.singleton("appManager").tell "Topics", "fetchTopics", {inputValue}, (tags = [], deletedTags = []) =>
          if not tags then @synonymController.showNoDataFound()
          else callback tags

    fields.Synonym.addSubView userRequestLineEdit = @synonymController.getView()
    @synonymController.addItemToSubmitQueue new TagAutoCompleteItemView({}, parent), parent if parent

  updateTopic:(topicItem)->
    topic = topicItem.data
    # log "Update this: ", topic
    controller = @
    modal = new KDModalViewWithForms
      title                       : "Update topic #{topic.title}"
      height                      : "auto"
      cssClass                    : "compose-message-modal"
      width                       : 779
      overlay                     : yes
      tabs                        :
        navigable                 : yes
        goToNextFormOnSubmit      : no
        forms                     :
          update                  :
            title                 : "Update Topic Details"
            callback              : (formData) =>
              formData.slug = @utils.slugify formData.slug.trim().toLowerCase()
              topic.modify formData, (err)=>
                new KDNotificationView
                  title : if err then err.message else "Updated successfully"
                # modal.modalTabs.forms.update.buttons.Update.hideLoader()
                modal.destroy()
            buttons               :
              Update              :
                style             : "modal-clean-green"
                type              : "submit"
                loader            :
                  color           : "#444444"
                  diameter        : 12
              Cancel              :
                style             : "modal-clean-gray"
                title             : "Cancel"
                callback          : ->
                  modal.destroy()
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
      KD.remote.api.JTag.some {}, options, callback

  # addATopic:(formData)->
  #   # log formData,"controller"
  #   KD.remote.api.JTag.create formData, (err, tag)->
  #     if err
  #       warn err,"there was an error creating topic!"
  #     else
  #       log tag,"created topic #{tag.title}"

  setCurrentViewHeader:(count)->
    if typeof 1 isnt typeof count
      @getView().$(".feeder-header span.optional_title").html count
      return no
    if count >= 20 then count = '20+'
    # return if count % 20 is 0 and count isnt 20
    # postfix = if count is 20 then '+' else ''
    count   = 'No' if count is 0
    result  = "#{count} result" + if count isnt 1 then 's' else ''
    title   = "#{result} found for <strong>#{@_searchValue}</strong>"
    @getView().$(".feeder-header").html title

  createContentDisplay:(topic, callback)->
    controller = new ContentDisplayControllerTopic null, topic
    contentDisplay = controller.getView()
    contentDisplay.on 'handleQuery', (query)=>
      controller.ready -> controller.feedController?.handleQuery? query
    @showContentDisplay contentDisplay
    @utils.defer -> callback contentDisplay

  showContentDisplay:(contentDisplay)->

    KD.singleton('display').emit "ContentDisplayWantsToBeShown", contentDisplay

  fetchTopics:({inputValue, blacklist}, callback)->

    KD.remote.api.JTag.byRelevance inputValue, {blacklist}, (err, tags, deletedTags)->
      unless err
        callback? tags, deletedTags
      else
        warn "there was an error fetching topics #{err.message}"

  # TODO ~ fix direct opening of topic links with query
  handleQuery:(query)->
    @ready =>
      {q} = query
      if q
        @emit "searchFilterChanged", q
      else
        @emit "searchFilterChanged", ""
        super query
