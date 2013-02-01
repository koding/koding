class GroupsAppController extends AppController

  @privateGroupOpenHandler =(event)->
    data = @getData()
    return yes  unless data.privacy is 'private'
    event.preventDefault()
    @emit 'PrivateGroupIsOpened', data

  [
    ERROR_UNKNOWN
    ERROR_NO_POLICY
    ERROR_APPROVAL_REQUIRED
    ERROR_PERSONAL_INVITATION_REQUIRED
    ERROR_MULTIUSE_INVITATION_REQUIRED
    ERROR_WEBHOOK_CUSTOM_FORM
  ] = [403010, 403001, 403002, 403003, 403004, 403005]

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
      @feedController.resultsController.on 'ItemWasAdded', @bound 'monitorGroupItemOpenLink'
      @putAddAGroupButton()
      @emit 'ready'

  monitorGroupItemOpenLink:(item)->
    item.on 'PrivateGroupIsOpened', @bound 'openPrivateGroup'

  getErrorModalOptions =(err)->
    switch err.accessCode
      when ERROR_NO_POLICY
        {
          title     : 'Sorry, this group does not have a membership policy!'
          content   : """
                      <div class='modalformline'>
                        The administrators have not yet defined a membership
                        policy for this private group.  No one may join this
                        group until a membership policy has been defined.
                      </div>
                      """
        }
      when ERROR_UNKNOWN
        {
          title     : 'Sorry, an unknown error has occurred!'
          content   : """
                      <div class='modalformline'>
                        Please try again later.
                      </div>
                      """
        }

  showErrorModal:(err)->
    modal = new KDModalView getErrorModalOptions err
    console.log {modal}


  openPrivateGroup:(group)->
    group.openGroup (err, policy)=>
      if err 
        @showErrorModal err
      else
        console.log 'access is granted!'



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

    modalOptions =
      title       : if isNewGroup then 'Create a new group' else "Edit the group '#{group.title}'"
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
              "Drop Image here"              :
                label             : "Avatar"
                itemClass         : KDImageUploadSingleView
                name              : "avatar"
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
                    ]
                }
              Title               :
                label             : "Title"
                itemClass         : KDInputView
                name              : "title"
                keydown           : (pubInst, event)->
                  setTimeout =>
                    slug = @utils.slugify @getValue()
                    modal.modalTabs.forms["General Settings"].inputs.Slug.setValue slug
                    modal.modalTabs.forms["General Settings"].inputs.SlugText.updatePartial '<span class="base">http://www.koding.com/Groups/</span>'+slug
                  , 1
                defaultValue      : Encoder.htmlDecode group.title ? ""
                placeholder       : 'Please enter a title here'
              SlugText                :
                itemClass : KDView
                cssClass : 'slug-url'
                partial : '<span class="base">http://www.koding.com/Groups/</span>'
                nextElementFlat :
                  Slug :
                    label             : "Slug"
                    itemClass         : KDInputView
                    name              : "slug"
                    cssClass          : 'hidden'
                    defaultValue      : group.slug ? ""
                    placeholder       : 'This value will be automatically generated'
                    disabled          : yes
              Description         :
                label             : "Description"
                type              : "textarea"
                itemClass         : KDInputView
                name              : "body"
                defaultValue      : Encoder.htmlDecode group.body ? ""
                placeholder       : 'Please enter a description here.'
              "Privacy settings"  :
                itemClass         : KDSelectBox
                label             : "Privacy settings"
                type              : "select"
                name              : "privacy"
                defaultValue      : group.privacy ? "public"
                selectOptions     : [
                  { title : "Public",    value : "public" }
                  { title : "Private",   value : "private" }
                ]
              "Visibility settings"  :
                itemClass         : KDSelectBox
                label             : "Visibility settings"
                type              : "select"
                name              : "visibility"
                defaultValue      : group.visibility ? "visible"
                selectOptions     : [
                  { title : "Visible",    value : "visible" }
                  { title : "Hidden",     value : "hidden" }
                ]

    unless isNewGroup
      modalOptions.tabs.forms.Members =
        title   : "User permissions"

    modal = new KDModalViewWithForms modalOptions, group

    modal.modalTabs.forms["General Settings"].inputs["Drop Image here"].on 'FileReadComplete', (stuff)->
      modal.modalTabs.forms["General Settings"].inputs["Drop Image here"].$('.kdfileuploadarea').css backgroundImage : "url(#{stuff.file.data})"
      modal.modalTabs.forms["General Settings"].inputs["Drop Image here"].$('span').addClass 'hidden'

    modal.modalTabs.forms["General Settings"].inputs.SlugText.updatePartial '<span class="base">http://www.koding.com/Groups/</span>'+modal.modalTabs.forms["General Settings"].inputs.Slug.getValue()

    unless isNewGroup
      modal.modalTabs.forms["Members"].addSubView new GroupsMemberPermissionsView {}, group

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
          @getSingleton('mainController').on "MyRolesRequested", (groupItem)=>
            groupItem.getData().fetchRoles console.log.bind console

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
    # controller = new ContentDisplayControllerGroups null, content
    # contentDisplay = controller.getView()
    groupView = new GroupView
      cssClass : "profilearea clearfix"
      delegate : @getView()
    , content
    
    contentDisplayController.emit "ContentDisplayWantsToBeShown", groupView
    callback groupView
    # console.log {contentDisplay}
    groupView.on 'PrivateGroupIsOpened', @bound 'openPrivateGroup'
    return groupView

  fetchTopics:({inputValue, blacklist}, callback)->

    KD.remote.api.JTag.byRelevance inputValue, {blacklist}, (err, tags)->
      unless err
        callback? tags
      else
        warn "there was an error fetching topics"
