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
    ERROR_POLICY
  ] = [403010, 403001, 403002, 403003, 403004, 403005, 403009]

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

  showInvitationsTab:(group, tabView)->
    # tab = modal.modalTabs.createTab title: 'Invitations', shouldShow:no
    pane = new KDTabPaneView name: 'Invitations'
    tab = tabView.tabView.addPane pane, no

    invitationRequestView = new GroupsInvitationRequestsView {}, group

    invitationRequestView.on 'BatchInvitationsAreSent', (count)->
      count = invitationRequestView.batchInvites.inputs.Count.getValue()
      group.sendSomeInvitations count, (err, message)->
        if message is null
          message = 'Done'
          invitationRequestView.prepareBulkInvitations()
        {statusInfo} = invitationRequestView.batchInvites.inputs
        statusInfo.updatePartial Encoder.htmlDecode message

    invitationRequestView.on 'InvitationIsSent', (request)->
      request.sendInvitation ->
        console.log 'invitation is sent', {arguments}

    tab.addSubView invitationRequestView

  removePaneByName:(tabView, paneName)->
    tabs = tabView.tabView
    invitePane = tabs.getPaneByName paneName
    tabs.removePane invitePane if invitePane

  hideInvitationsTab:(tabView)-> 
    @removePaneByName tabView, 'Invitations'

  showApprovalTab:(group, tabView)->
    pane = new KDTabPaneView name: 'Approval requests'
    tab = tabView.tabView.addPane pane, no

    approvalRequestView = new GroupsApprovalRequestsView {}, group

    tab.addSubView approvalRequestView

  hideApprovalTab:(tabView)->
    @removePaneByName tabView, 'Approval requests'

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
    group.canOpenGroup (err, policy)=>
      if err
        @showErrorModal group, err
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
                  setTimeout =>
                    slug = @utils.slugify @getValue()
                    modal.modalTabs.forms["General Settings"].inputs.Slug.setValue slug
                    # modal.modalTabs.forms["General Settings"].inputs.SlugText.updatePartial '<span class="base">http://www.koding.com/Groups/</span>'+slug
                  , 1
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

    # unless isNewGroup
    #   modalOptions.tabs.forms.Permissions =
    #     title : 'Permissions'
    #     cssClass : 'permissions-modal'
    #   modalOptions.tabs.forms.Members =
    #     title   : "User permissions"
    #   if isPrivateGroup
    #     modalOptions.tabs.forms['Membership policy'] =
    #       title   : "Membership policy"

    modal = new KDModalViewWithForms modalOptions, group

    {forms} = modal.modalTabs

    avatarUploadView = forms["General Settings"].inputs["Avatar"]
    avatarUploadView.on 'FileReadComplete', (stuff)->
      avatarUploadView.$('.kdfileuploadarea').css
        backgroundImage : "url(#{stuff.file.data})"
      avatarUploadView.$('span').addClass 'hidden'

    # unless isNewGroup
    #   if isPrivateGroup
    #     group.fetchMembershipPolicy (err, policy)=>
    #       membershipPolicyView = new GroupsMembershipPolicyView {}, policy

    #       membershipPolicyView.on 'MembershipPolicyChanged', (formData)=>
    #         @updateMembershipPolicy group, policy, formData, membershipPolicyView

    #       forms["Membership policy"].addSubView membershipPolicyView

    #       if policy.invitationsEnabled
    #         @showInvitationsTab group, modal, forms
    #       else if policy.approvalEnabled
    #         @showApprovalTab group, modal, forms

    #   forms["Members"].addSubView new GroupsMemberPermissionsView {}, group

    #   forms["Permissions"].addSubView permissionsLoader = new KDLoaderView
    #     size          :
    #       width       : 32

    #   addPermissionsView = (newPermissions)=>
    #     group.fetchRoles (err,roles)->
    #       group.fetchPermissions (err, permissionSet)=>
    #         permissionsLoader.hide()
    #         unless err
    #           if newPermissions
    #             permissionSet.permissions = newPermissions
    #           if @permissions then forms["Permissions"].removeSubView @permissions
    #           forms["Permissions"].addSubView @permissions = new PermissionsModal {
    #             privacy: group.privacy
    #             permissionSet
    #             roles
    #           }, group
    #           @permissions.emit 'RoleViewRefreshed'
    #           @permissions.on 'RoleWasAdded', (newPermissions,role,copy)=>
    #             copiedPermissions = []
    #             for permission of newPermissions
    #               if newPermissions[permission].role is copy
    #                 copiedPermissions.push
    #                   module : newPermissions[permission].module
    #                   permissions : newPermissions[permission].permissions
    #                   role : role
    #             for item in copiedPermissions
    #               newPermissions.push item
    #             addPermissionsView(newPermissions)
    #             # @render()
    #         else
    #           forms['Permissions'].addSubView new KDView
    #             partial : 'No access'

    #   permissionsLoader.show()
    #   addPermissionsView()

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

  getMembershipPolicyChangeData:(invitationsEnabled)->
    if invitationsEnabled
      {
        remainingInvitationType: 'invitation'
        errorMessage:
          """
          This group has pending invitations.  Before you can disable
          invitations, you'll need to either resolve the pending invitations
          by either sending them or deleting them.
          """
        policyChangeButtons: ['Send all', 'Delete all', 'cancel']
      }
    else
      {
        remainingInvitationType: 'basic approval'
        errorMessage:
          """
          This group has pending approvals.  Before you can enable invitations,
          you'll need to resolve the pending approvals by either approving
          them or declining them.
          """
        policyChangeButtons: ['Approve all', 'Decline all', 'cancel']
      }

  cancelMembershipPolicyChange:(policy, membershipPolicyView, modal)->
    membershipPolicyView.enableInvitations.setValue policy.invitationsEnabled

  updateMembershipPolicy:(group, policy, formData, membershipPolicyView, callback)->
    complete = ->
      group.modifyMembershipPolicy formData, ->
        membershipPolicyView.emit 'MembershipPolicyChangeSaved'
    if policy.invitationsEnabled isnt formData.invitationsEnabled

      {remainingInvitationType, errorMessage, policyChangeButtons} =
        @getMembershipPolicyChangeData policy.invitationsEnabled

      targetSelector =
        invitationType: remainingInvitationType
        status: 'pending'

      group.countInvitationRequests {}, targetSelector, (err, count)=>
        if err then handleError err
        else if count isnt 0
          # handlers for buttons:
          actions = [
            @resolvePendingRequests.bind this, group, yes, complete
            @resolvePendingRequests.bind this, group, no, complete
            (modal)-> modal.cancel()
          ]
          cssClasses = ['modal-clean-green','modal-clean-red','modal-cancel']
          policyChangeButtons = policyChangeButtons.reduce (acc, title, i)->
            acc[title] = {
              title
              cssClass: cssClasses[i]
              callback: actions[i]
            }
            return acc
          , {}
          handleError {
            message : errorMessage
            cancel  : @cancelMembershipPolicyChange.bind this, policy, membershipPolicyView
          }, policyChangeButtons
        else complete()
    else complete()

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


  selectTab:(groupView, tabName, konstructor)->
    groupView.assureTab tabName, konstructor

  handleMembershipPolicyTabs:(policy, group, view)->
    if policy.invitationsEnabled
      unless view.tabView.getPaneByName 'Invitations'
        @showInvitationsTab group, view
      if view.tabView.getPaneByName 'Approval requests'
        @hideApprovalTab view
    else
      if policy.approvalEnabled
        unless view.tabView.getPaneByName 'Approval requests'
          @showApprovalTab group, view
        if view.tabView.getPaneByName 'Invitations'
          @hideInvitationsTab view
      else
        @hideInvitationsTab view
        @hideApprovalTab view

  prepareMembershipPolicyTab:(group, view, groupView)->
    group.fetchMembershipPolicy (err, policy)=>

      view.loader.hide()
      view.loaderText.hide()

      membershipPolicyView = new GroupsMembershipPolicyView {}, policy

      membershipPolicyView.on 'MembershipPolicyChanged', (formData)=>
        @updateMembershipPolicy group, policy, formData, membershipPolicyView

      membershipPolicyView.on 'MembershipPolicyChangeSaved', =>
        group.fetchMembershipPolicy (err, policy)=>
          @handleMembershipPolicyTabs policy, group, groupView

      @handleMembershipPolicyTabs policy, group, groupView

      view.addSubView membershipPolicyView

  showContentDisplay:(group, callback=->)->
    contentDisplayController = @getSingleton "contentDisplayController"
    # controller = new ContentDisplayControllerGroups null, content
    # contentDisplay = controller.getView()
    groupView = new GroupView
      cssClass : "group-content-display"
      delegate : @getView()
    , group

    groupView.on 'ReadmeSelected',
      groupView.lazyBound 'assureTab', 'Readme', yes, GroupReadmeView

    groupView.on 'SettingsSelected',
      groupView.lazyBound 'assureTab', 'Settings', no, GroupGeneralSettingsView

    groupView.on 'PermissionsSelected',
      groupView.lazyBound 'assureTab', 'Permissions', no, GroupPermissionsView, {delegate : groupView}

    groupView.on 'MembersSelected',
      groupView.lazyBound 'assureTab', 'Members', no, GroupsMemberPermissionsView

    groupView.on 'MembershipPolicySelected',
      groupView.lazyBound 'assureTab', 'Membership policy', no, GroupsMembershipPolicyTabView,
        (pane, view)=> @prepareMembershipPolicyTab group, view, groupView

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
