class GroupsAppController extends AppController

  KD.registerAppClass @,
    name         : "Groups"
    route        : "Groups"
    hiddenHandle : yes

  @privateGroupOpenHandler =(event)->
    event.preventDefault()
    @emit 'PrivateGroupIsOpened', @getData()

  [
    ERROR_UNKNOWN
    ERROR_NO_POLICY
    ERROR_APPROVAL_REQUIRED
    ERROR_PERSONAL_INVITATION_REQUIRED
    ERROR_MULTIUSE_INVITATION_REQUIRED
    ERROR_WEBHOOK_CUSTOM_FORM
    ERROR_POLICY
  ] = [403010, 403001, 403002, 403003, 403004, 403005, 403009]

  constructor:(options = {}, data)->

    options.view    = new GroupsMainView
      cssClass      : "content-page groups"
    options.appInfo =
      name          : "Groups"

    super options, data

    @listItemClass = GroupsListItemView
    @controllers = {}

    @getSingleton('windowController').on "FeederListViewItemCountChanged", (count, itemClass, filterName)=>
      if @_searchValue and itemClass is @listItemClass then @setCurrentViewHeader count

  createFeed:(view)->
    KD.getSingleton("appManager").tell 'Feeder', 'createContentFeedController', {
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
                everything.forEachItemByIndex groups, (view)->
                  view.setClass 'own-group'
        following           :
          title             : "My groups"
          dataSource        : (selector, options, callback)=>
            KD.whoami().fetchGroups (err, items)=>
              for item in items
                item.followee = true
              callback err, (item.group for item in items)
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
    defaultOptions =
      buttons       :
        Cancel      :
          cssClass  : "modal-clean-red"
          callback  : (event)-> @getDelegate().destroy()
    customOptions = switch err.accessCode
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
      when ERROR_POLICY
        {
          title     : 'This is a private group'
          content   :
            """
            <div class="modalformline">#{err.message}</div>
            """
        }

    if err.accessCode is ERROR_POLICY
      defaultOptions.buttons['Request access'] =
        cssClass    : 'modal-clean-green'
        loader      :
          color     : "#ffffff"
          diameter  : 12
        callback    : -> @getDelegate().emit 'AccessIsRequested'

    _.extend defaultOptions, customOptions

  removePaneByName:(tabView, paneName)->
    tabs = tabView.tabView
    invitePane = tabs.getPaneByName paneName
    tabs.removePane invitePane if invitePane

  showErrorModal:(group, err)->
    modal = new KDModalView getErrorModalOptions err
    modal.on 'AccessIsRequested', =>
      @requestAccess group, (err)-> modal.destroy()

  requestAccess:(group, callback)->
    group.requestAccess (err)->
      callback err
      new KDNotificationView title:
        if err then err.message
        else "Invitation has been requested!"

  openPrivateGroup:(group)->
    group.canOpenGroup (err, hasPermission)=>
      if err
        @showErrorModal group, err
      else if hasPermission
        @openGroup group

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
    isPrivateGroup = 'private' is group.privacy

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
              "Avatar"              :
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
                  @utils.defer =>
                    slug = @utils.slugify @getValue()
                    modal.modalTabs.forms["General Settings"].inputs.Slug.setValue slug
                    # modal.modalTabs.forms["General Settings"].inputs.SlugText.updatePartial '<span class="base">http://www.koding.com/Groups/</span>'+slug
                defaultValue      : Encoder.htmlDecode group.title ? ""
                placeholder       : 'Please enter a title here'
              # SlugText                :
              #   itemClass : KDView
              #   cssClass : 'slug-url'
              #   partial : '<span class="base">http://www.koding.com/</span>'
              #   nextElementFlat :
              Slug :
                label             : "Slug"
                itemClass         : KDInputView
                name              : "slug"
                # cssClass          : 'hidden'
                defaultValue      : group.slug ? ""
                placeholder       : 'This value will be automatically generated'
                # disabled          : yes
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

    modal = new KDModalViewWithForms modalOptions, group

    {forms} = modal.modalTabs

    avatarUploadView = forms["General Settings"].inputs["Avatar"]
    avatarUploadView.on 'FileReadComplete', (event)->
      avatarUploadView.$('.kdfileuploadarea').css
        backgroundImage : "url(#{event.file.data})"
      avatarUploadView.$('span').addClass 'hidden'

  handleError =(err, buttons)->
    unless buttons
      new KDNotificationView title: err.message
    else

      modalOptions =
        title   : "Error#{if err.code then " #{code}" else ""}"
        content : "<div class='modalformline'><p>#{err.message}</p></div>"
        buttons : {}
        cancel  : err.cancel

      Object.keys(buttons).forEach (buttonTitle)->
        buttonOptions = buttons[buttonTitle]
        oldCallback = buttonOptions.callback
        buttonOptions.callback = -> oldCallback modal

        modalOptions.buttons[buttonTitle] = buttonOptions

      modal = new KDModalView modalOptions

  resolvePendingRequests:(group, takeDestructiveAction, callback, modal)->
    group.resolvePendingRequests takeDestructiveAction, (err)->
      modal.destroy()
      handleError err  if err?
      callback err

  cancelMembershipPolicyChange:(policy, membershipPolicyView, modal)->
    membershipPolicyView.enableInvitations.setValue policy.invitationsEnabled

  updateMembershipPolicy:(group, policy, formData, membershipPolicyView, callback)->
    group.modifyMembershipPolicy formData, ->
      membershipPolicyView.emit 'MembershipPolicyChangeSaved'

  editPermissions:(group)->
    group.getData().fetchPermissions (err, permissionSet)->
      if err
        new KDNotificationView title: err.message
      else
        permissionsModal = new PermissionsModal {
          privacy: group.getData().privacy
          permissionSet
        }, group

  loadView:(mainView, firstRun = yes)->

    if firstRun
      mainView.on "searchFilterChanged", (value) =>
        return if value is @_searchValue
        @_searchValue = Encoder.XSSEncode value
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
            groupData = groupItem.getData()
            groupData.canEditGroup (err, hasPermission)=>
              unless hasPermission
                new KDNotificationView title: 'Access denied'
              else
                @showGroupSubmissionView groupData
          @getSingleton('mainController').on "MyRolesRequested", (groupItem)=>
            groupItem.getData().fetchRoles console.log.bind console

      @createFeed mainView
    # mainView.on "AddATopicFormSubmitted",(formData)=> @addATopic formData

  openGroup:(group)->
    {slug, title} = group
    modal = new KDModalView
      title           : title
      content         : "<div class='modalformline'>You are about to open a third-party group.</div>"
      height          : "auto"
      overlay         : yes
      buttons         : 
        cancel        :
          style       : 'modal-cancel'
          callback    : -> modal.destroy()
    modal.buttonHolder.addSubView new CustomLinkView
      href    : "/#{slug}/Activity"
      target  : slug
      title   : 'Open group'
      # click   : (event)->
      #   event.preventDefault()
      #   @getSingleton('windowManager').open @href, slug


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

  prepareReadmeTab:->
    {groupView} = this
    group = groupView.getData()
    groupView.tabView.addPane pane = new KDTabPaneView
      name: 'Readme'
    pane.addSubView new GroupReadmeView {}, group
    return pane

  prepareSettingsTab:->
    pane = @groupView.createLazyTab 'Settings', GroupGeneralSettingsView
    return pane

  preparePermissionsTab:->
    {groupView} = this
    pane = groupView.createLazyTab 'Permissions', GroupPermissionsView,
      delegate: groupView
    return pane

  prepareMembersTab:->
    {groupView} = this
    group = groupView.getData()
    pane = groupView.createLazyTab 'Members', GroupsMemberPermissionsView,
      (pane, view)=>
        pane.on 'PaneDidShow', ->
          view.refresh()  if pane.tabHandle.isDirty
          pane.tabHandle.markDirty no

    group.on 'NewMember', ->
      {tabHandle} = pane
      tabHandle.markDirty()
    return pane

  prepareMembershipPolicyTab:(group, view, groupView)->
    {groupView} = this
    group = groupView.getData()
    pane = groupView.createLazyTab 'Membership policy', GroupsMembershipPolicyView,
      (pane, view)=>

        group.fetchMembershipPolicy (err, policy)=>
          view.loader.hide()
          view.loaderText.hide()

          membershipPolicyView = new GroupsMembershipPolicyDetailView {}, policy

          membershipPolicyView.on 'MembershipPolicyChanged', (formData)=>
            @updateMembershipPolicy group, policy, formData, membershipPolicyView

          membershipPolicyView.on 'MembershipPolicyChangeSaved', => console.log 'sssaved'

          view.addSubView membershipPolicyView
    return pane

  prepareInvitationsTab:->
    {groupView} = this
    group = groupView.getData()
    pane = groupView.createLazyTab 'Invitations', GroupsInvitationRequestsView,
      (pane, invitationRequestView)->

        invitationRequestView.on 'BatchInvitationsAreSent', (count)->
          count = invitationRequestView.batchInvites.inputs.Count.getValue()
          group.sendSomeInvitations count, (err, message)->
            if message is null
              message = 'Done'
              invitationRequestView.prepareBulkInvitations()
            {statusInfo} = invitationRequestView.batchInvites.inputs
            statusInfo.updatePartial Encoder.htmlDecode message

        invitationRequestView.on 'RequestIsApproved', (request)->
          request.approveInvitation()

        invitationRequestView.on 'RequestIsDeclined', (request)->
          request.declineInvitation()

        pane.on 'PaneDidShow', ->
          invitationRequestView.refresh()  if pane.tabHandle.isDirty
          pane.tabHandle.markDirty no

    group.on 'NewInvitationRequest', ->
      pane.tabHandle.markDirty()

    return pane

  showContentDisplay:(group, callback=->)->
    contentDisplayController = @getSingleton "contentDisplayController"
    # controller = new ContentDisplayControllerGroups null, content
    # contentDisplay = controller.getView()
    @groupView = groupView = new GroupView
      cssClass : "group-content-display"
      delegate : @getView()
    , group

    @prepareReadmeTab()
    @prepareSettingsTab()
    @preparePermissionsTab()
    @prepareMembersTab()

    if 'private' is group.privacy
      @prepareMembershipPolicyTab()
      @prepareInvitationsTab()

    contentDisplayController.emit "ContentDisplayWantsToBeShown", groupView
    # console.log {contentDisplay}
    groupView.on 'PrivateGroupIsOpened', @bound 'openPrivateGroup'
    return groupView

