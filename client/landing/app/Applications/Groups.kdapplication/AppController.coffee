class GroupsAppController extends AppController

  constructor:(options, data)->
    options = $.extend
      # view : if /localhost/.test(location.host) then new TopicsMainView cssClass : "content-page topics" else new TopicsComingSoon
      # view : new TopicsComingSoon
      view : new GroupsMainView(cssClass : "content-page groups")
    ,options
    super options,data
    @listItemClass = GroupsListItemView
    @controllers = {}

    @getSingleton('windowController').on "FeederListViewItemCountChanged", (count, itemClass, filterName)=>
      if @_searchValue and itemClass is @listItemClass then @setCurrentViewHeader count

  bringToFront:()->
    @propagateEvent (KDEventType : 'ApplicationWantsToBeShown', globalEvent : yes),
      options :
        name : 'Groups'
      data : @getView()

  createFeed:(view)->
    appManager.tell 'Feeder', 'createContentFeedController', {
      itemClass          : @listItemClass
      limitPerPage          : 20
      # feedMessage           :
      #   title                 : "Topics organize shared content on Koding. Tag items when you share, and follow topics to see content relevant to you in your activity feed."
      #   messageLocation       : 'Topics'
      help                  :
        subtitle            : "Learn About Groups"
        tooltip             :
          title             : "<p class=\"bigtwipsy\">Groups are the basic unit of Koding society.</p>"
          placement         : "above"
      filter                :
        everything          :
          title             : "All groups"
          optional_title    : if @_searchValue then "<span class='optional_title'></span>" else null
          dataSource        : (selector, options, callback)=>
            {JGroup} = KD.remote.api
            if @_searchValue
              @setCurrentViewHeader "Searching for <strong>#{@_searchValue}</strong>..."
              JGroup.byRelevance @_searchValue, options, callback
            else
              JGroup.streamModels selector, options, callback
          dataEnd           :({resultsController}, ids)->
            {JGroup} = KD.remote.api
            JGroup.fetchMyMemberships ids, (err, groups)->
              if err then error err
              else
                {everything} = resultsController.listControllers
                everything.forEachItemByIndex groups, ({joinButton,enterButton})->
                  joinButton.setState 'Leave'
                  joinButton.redecorateState()
                  enterButton.show()
        following           :
          title             : "Following"
          dataSource        : (selector, options, callback)=>
            KD.whoami().fetchGroups selector, options, (err, items)=>
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
      view.addSubView @_lastSubview = controller.getView()
      @feedController = controller
      @putAddAGroupButton()
      @emit 'ready'

  putAddAGroupButton:->
    {facetsController} = @feedController
    innerNav = facetsController.getView()
    innerNav.addSubView addButton = new KDButtonView
      title     : "Create a Group"
      style     : "small-gray"
      callback  : => @showGroupSubmissionView()


  _createGroupHandler =(formData)->
    KD.remote.api.JGroup.create formData, (err, group)=>
      if err
        new KDNotificationView
          title: err.message
          duration: 1000
      else
        new KDNotificationView
          title: 'Group was created!'
          duration: 1000
        @showContentDisplay group

  _updateGroupHandler =(group, formData)->
    group.modify formData, (err)->
      if err
        new KDNotificationView
          title: err.message
          duration: 1000
      else
        new KDNotificationView
          title: 'Group was updated!'
          duration: 1000

  showGroupSubmissionView:(group)->
    unless group?
      group = {}
      isNewGroup = yes
    modal = new KDModalViewWithForms #GroupAdminModal
      title       : if isNewGroup then 'Create a new group' else "Edit the group '#{group.title}'"
      # content     : "<div class='modalformline'>With great power comes great responsibility. ~ Stan Lee</div>"
      height      : 'auto'
      cssClass    : "compose-message-modal admin-kdmodal group-admin-modal"
      width       : 500
      overlay     : yes
      tabs        :
        navigable : yes
        goToNextFormOnSubmit: no
        forms     :
          "General Settings":
            title: if isNewGroup then 'Create a group' else 'Edit group'
            callback:(formData)=>
              if isNewGroup
                _createGroupHandler.call @, formData
              else
                _updateGroupHandler group, formData
              modal.destroy()
            buttons:
              Save                :
                style             : "modal-clean-gray"
                type              : "submit"
                loader            :
                  color           : "#444444"
                  diameter        : 12
              Cancel              :
                style             : "modal-clean-gray"
                loader            :
                  color           : "#ffffff"
                  diameter        : 16
                callback          : -> modal.destroy()
            fields:
              Title               :
                label             : "Title"
                itemClass         : KDInputView
                name              : "title"
                keydown           : (pubInst, event)->
                  setTimeout =>
                    slug = @utils.slugify @getValue()
                    modal.modalTabs.forms["General Settings"].inputs.Slug.setValue slug
                  , 1
                defaultValue      : group.title ? ""
              Slug                :
                label             : "Slug"
                itemClass         : KDInputView
                name              : "slug"
                defaultValue      : group.slug ? ""
              Description         :
                label             : "Description"
                type              : "textarea"
                itemClass         : KDInputView
                name              : "body"
                defaultValue      : group.body ? ""
              "Privacy settings"  :
                label             : "Privacy settings"
                type              : "select"
                name              : "privacy"
                defaultValue      : group.privacy ? "public"
                selectOptions     : [
                  { title : "Public",    value : "public" }
                  { title : "Private",   value : "private" }
                ]
              "Visibility settings"  :
                label             : "Visibility settings"
                type              : "select"
                name              : "visibility"
                defaultValue      : group.visibility ? "visible"
                selectOptions     : [
                  { title : "Visible",    value : "visible" }
                  { title : "Hidden",     value : "hidden" }
                ]
          "Avatar":
            title : "Select an Avatar"
            #<img class='avatar-image' src='#{group.avatar or "http://lorempixel.com/#{200+@utils.getRandomNumber(10)}/#{200+@utils.getRandomNumber(10)}"}'/>
            partial : "<div class='image-wrapper'></div>"
            callback :(formData)=>
              log 'image data, ready for S3 upload',formData

              for image in formData.images
                if image
                  modal.$('.image-wrapper').css backgroundImage : "url(#{image.small})"
                  modal.modalTabs.forms["General Settings"].addCustomData 'avatar', image.small
              # access data like this. formData.images may have undefined values for some reason
              # for image in formData.images
              #   if image
              #     modal.$('.image-wrapper').append("<img src='#{image.small}'/>")
              #     modal.$('.image-wrapper').append("<img src='#{image.medium}'/>")
              #     modal.$('.image-wrapper').append("<img src='#{image.big}'/>")

              modal.modalTabs.forms['Avatar'].buttons['Use this image'].hideLoader()
              # modal.destroy()

            buttons:
              "Use this image"    :
                style             : "modal-clean-gray"
                type              : "submit"
                loader            :
                  color           : "#444444"
                  diameter        : 12
              Cancel              :
                style             : "modal-clean-gray"
                loader            :
                  color           : "#ffffff"
                  diameter        : 16
                callback          :=>
                  modal.destroy()
            fields:
              "Drop Image here"              :
                label             : "Avatar"
                itemClass         : KDImageUploadSingleView
                name              : "group-avatar"
                limit             : 1
                preview           : 'thumbs'
                actions         : {
                  big    :
                    [
                      'scale', {
                        shortest: 400
                      }
                      'crop', {
                        width   : 400
                        height  : 400
                      }
                    ]
                  medium         :
                    [
                      'scale', {
                        shortest: 200
                      }
                      'crop', {
                        width   : 200
                        height  : 200
                      }
                    ]
                  small         :
                    [
                      'scale', {
                        shortest: 60
                      }
                      'crop', {
                        width   : 60
                        height  : 60
                      }
                      # 'blur', {
                      #   radius : 0
                      # }
                    ]
                }
    , group

    modal.modalTabs.forms["Avatar"].buttons["Use this image"].enable()
    modal.modalTabs.forms["Avatar"].inputs["Drop Image here"].on 'FileReadComplete', (stuff)->
      # modal.$('img.avatar-image').attr 'src' : stuff.file.data
      modal.$('div.image-wrapper').css backgroundImage : "url(#{stuff.file.data})"

  editPermissions:(group)->
    group.getData().fetchPermissions (err, permissionSet)->
      if err
        new KDNotificationView title: err.message
      else
        permissionsModal = new PermissionsModal {
          privacy: group.getData().privacy
          permissionSet
        }, group

        # permissionsGrid = new PermissionsGrid {
        #   privacy: group.getData().privacy
        #   permissionSet
        # }

        # modal = new KDModalView
        #   title     : "Edit permissions"
        #   content   : ""
        #   overlay   : yes
        #   cssClass  : "new-kdmodal permission-modal"
        #   width     : 500
        #   height    : "auto"
        #   buttons:
        #     Save          :
        #       style       : "modal-clean-gray"
        #       loader      :
        #         color     : "#444444"
        #         diameter  : 12
        #       callback    : ->
        #         log permissionsGrid.reducedList()
        #         # group.getData().updatePermissions(
        #         #   permissionsGrid.reducedList()
        #         #   console.log.bind(console) # TODO: do something with this callback
        #         # )
        #         modal.destroy()
        #     Cancel        :
        #       style       : "modal-clean-gray"
        #       loader      :
        #         color     : "#ffffff"
        #         diameter  : 16
        #       callback    : -> modal.destroy()
        # modal.addSubView permissionsGrid

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
        @listItemClass = GroupsListItemViewEditable
        if firstRun
          @getSingleton('mainController').on "EditPermissionsButtonClicked", (groupItem)=>
            @editPermissions groupItem
          @getSingleton('mainController').on "EditGroupButtonClicked", (groupItem)=>
            @showGroupSubmissionView groupItem.getData()

      @createFeed mainView
    # mainView.on "AddATopicFormSubmitted",(formData)=> @addATopic formData

  fetchSomeTopics:(options = {}, callback)->

    options.limit    or= 6
    options.skip     or= 0
    options.sort     or=
      "counts.followers": -1
    selector = options.selector or {}
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
    controller = new ContentDisplayControllerGroups null, content
    contentDisplay = controller.getView()
    contentDisplayController.emit "ContentDisplayWantsToBeShown", contentDisplay
    callback contentDisplay

  fetchTopics:({inputValue, blacklist}, callback)->

    KD.remote.api.JTag.byRelevance inputValue, {blacklist}, (err, tags)->
      unless err
        callback? tags
      else
        warn "there was an error fetching topics"
