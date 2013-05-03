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

    @utils.defer @bound 'init'

  init:->
    mainController = @getSingleton 'mainController'
    mainController.on 'AccountChanged', @bound 'resetUserArea'
    mainController.on 'NavigationLinkTitleClick', (pageInfo)=>
      KD.getSingleton('router').handleRoute if pageInfo.path
        if pageInfo.topLevel then pageInfo.path
        else
          {group} = @userArea
          "#{unless group is 'koding' then '/'+group else ''}#{pageInfo.path}"
    @groups = {}
    @currentGroupData = new GroupData

    mainController.on 'groupAccessRequested', @showRequestAccessModal.bind this
    mainController.on 'groupJoinRequested',   @joinGroup.bind this
    mainController.on 'loginRequired',        @loginRequired.bind this

  getCurrentGroupData:-> @currentGroupData

  getCurrentGroup:->
    if Array.isArray @currentGroupData.data
      return @currentGroupData.data.first
    return @currentGroupData.data

  openGroupChannel:(group, callback=->)->
    @groupChannel = KD.remote.subscribe "group.#{group.slug}", {
      serviceType : 'group'
      group       : group.slug
      isExclusive : yes
      isReadOnly  : yes
    }
    # TEMP SY: to be able to work in a vagrantless env
    # to avoid shared authworker's message getting lost
    if location.hostname is "localhost"
      callback()
    else
      @groupChannel.once 'setSecretName', callback

  changeGroup:(groupName='koding', callback=->)->
    return callback()  if @currentGroup is groupName
    throw new Error 'Cannot change the group!'  if @currentGroup?
    @once 'GroupChanged', (groupName, group)-> callback null, groupName, group
    unless @currentGroup is groupName
      @setGroup groupName
      KD.remote.cacheable groupName, (err, models)=>
        if err then callback err
        else if models?
          [group] = models
          @currentGroupData.setGroup group
          @openGroupChannel group, => @emit 'GroupChanged', groupName, group

  getUserArea:-> @userArea

  setUserArea:(userArea)->
    @emit 'UserAreaChanged', userArea  if not _.isEqual userArea, @userArea
    @userArea = userArea

  getGroupSlug:-> @currentGroup

  setGroup:(groupName)->
    @currentGroup = groupName
    @setUserArea {
      group: groupName, user: KD.whoami().profile.nickname
    }

  resetUserArea:(account)->
    @setUserArea {
      group: @currentGroup ? 'koding', user: account.profile.nickname
    }

  createFeed:(view, loadFeed = no)->
    KD.getSingleton("appManager").tell 'Feeder', 'createContentFeedController', {
      itemClass             : @listItemClass
      limitPerPage          : 20
      useHeaderNav          : yes
      listCssClass          : "groups"
      help                  :
        subtitle            : "Learn About Groups"
        tooltip             :
          title             : "<p class=\"bigtwipsy\">Groups are the basic unit of Koding society.</p>"
          placement         : "above"
      onboarding            :
        everything          :
          """
            <h3 class='title'>Koding groups is a simple way to connect and interact with people who share
            your interests.</h3>

            <p>When you join a group within a community such as your univeristy or you
company, you can share virtual machines, files and stay up to date on the
activites of others in your group.</p>

            <h3 class='title'>Easy to get started and safe</h3>

            <p>Groups are free to create. You decide who can join and what they see.</p>
          """
        mine                : "<h3 class='title'>yooo onboard me for my groops!!!</h3>"
      filter                :
        everything          :
          title             : "All groups"
          optional_title    : if @_searchValue then "<span class='optional_title'></span>" else null
          dataSource        : (selector, options, callback)=>
            {JGroup} = KD.remote.api
            if @_searchValue
              @setCurrentViewHeader "Searching for <strong>#{@_searchValue}</strong>..."
              JGroup.byRelevance @_searchValue, options, (err, items, rest...)=>
                callback err, items, rest...
                # to trigger dataEnd
                unless err
                  ids = item.getId?() for item in items
                  callback null, null, ids
            else
              JGroup.streamModels selector, options, callback
          dataEnd           :({resultsController}, ids)=>
            {everything} = resultsController.listControllers
            @markMemberAndOwnGroups everything, ids
          dataError         :(controller, err)->
            log "Seems something broken:", controller, err

        mine                :
          title             : "My groups"
          dataSource        : (selector, options, callback)=>
            KD.whoami().fetchGroups (err, items)=>
              console.log items
              ids = []
              for item in items
                item.followee = true
                ids.push item.group.getId()
              callback err, (item.group for item in items)
              callback err, null, ids
          dataEnd           :({resultsController}, ids)=>
            {mine} = resultsController.listControllers
            @markMemberAndOwnGroups mine, ids
        # recommended         :
        #   title             : "Recommended"
        #   dataSource        : (selector, options, callback)=>
        #     callback 'Coming soon!'
      sort                  :
        'counts.members'    :
          title             : "Most popular"
          direction         : -1
        'meta.modifiedAt'   :
          title             : "Latest activity"
          direction         : -1
        'counts.posts'      :
          title             : "Most activity"
          direction         : -1
    }, (controller)=>
      view.addSubView @_lastSubview = controller.getView()
      @feedController = controller
      @feedController.resultsController.on 'ItemWasAdded', @bound 'monitorGroupItemOpenLink'
      @feedController.loadFeed() if loadFeed
      @putAddAGroupButton()
      @emit 'ready'

  markMemberAndOwnGroups:(controller, ids)->
    fetchRoles =
      member: (view)-> view.markMemberGroup()
      admin : (view)-> view.markGroupAdmin()
      owner : (view)-> view.markOwnGroup()
    for as, callback of fetchRoles
      do (as, callback)->
        KD.remote.api.JGroup.fetchMyMemberships ids, as, (err, groups)->
          return error err if err
          controller.forEachItemByIndex groups, callback

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
      @getSingleton('staticGroupController')?.emit 'AccessIsRequested', group
      @requestAccess group, (err)-> modal.destroy()

  showRequestAccessModal:(group, isApproval, callback=->)->
    if isApproval
      title   = 'Request Access'
      content = 'Membership to this group requires administrative approval.'
      success = "Thanks! You'll receive an email when group's admin accepts you."
    else
      title   = 'Request an Invite'
      content = 'Membership to this group requires an invitation.'
      success = "Invitation has been sent to the group's admin."

    modal = new KDModalView
      title          : title
      overlay        : yes
      width          : 300
      height         : 'auto'
      content        : "<div class='modalformline'><p>#{content}</p></div>"
      buttons        :
        request      :
          title      : title
          loader     :
            color    : "#ffffff"
            diameter : 12
          style      : 'modal-clean-green'
          callback   : (event)->
            group.requestAccess (err)->
              modal.buttons.request.hideLoader()
              callback err
              new KDNotificationView title:
                if err then err.message else success
              modal.destroy() unless err

  joinGroup:(group)->
    group.join (err, response)=>
      if err
        error err
        new KDNotificationView
          title : "An error occured, please try again"
      else
        new KDNotificationView
          title : "You successfully joined the group!"
        @getSingleton('mainController').emit 'JoinedGroup'

  openPrivateGroup:(group)->
    group.canOpenGroup (err, hasPermission)=>
      if err
        @showErrorModal group, err
      else if hasPermission
        @openGroup group

  putAddAGroupButton:->
    if KD.isLoggedIn()
      {facetsController} = @feedController
      innerNav = facetsController.getView()
      innerNav.addSubView addButton = new KDButtonView
        tooltip   :
          title   : "Create a Group"
        style     : "small-gray"
        iconOnly  : yes
        callback  : => @showGroupSubmissionView()

  _createGroupHandler =(formData)->

    if formData.privacy in ['by-invite', 'by-request', 'same-domain']
      formData.privacy = 'private'

    KD.remote.api.JGroup.create formData, (err, group)=>
      if err
        new KDNotificationView
          title: err.message
          duration: 1000
      else
        new KDNotificationView
          title   : 'Group was created!'
          duration: 1000
        @createContentDisplay group

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

  showGroupSubmissionView:->

    verifySlug = (slug)->
      modal.modalTabs.forms["General Settings"].inputs.Slug.setValue slug
      KD.remote.api.JName.one
        name : "#{slug}"
      , (err,name)=>
        if name
          modal.modalTabs.forms["General Settings"].inputs.Slug.setClass 'slug-taken'
        else
          modal.modalTabs.forms["General Settings"].inputs.Slug.unsetClass 'slug-taken'

    getGroupType = ->
      modal.modalTabs.forms["Select group type"].inputs.type.getValue()

    getPrivacyDefault = ->
      switch getGroupType()
        when 'educational'  then 'by-request'
        when 'company'      then 'by-invite'
        when 'project'      then'public'
        when 'custom'       then 'public'

    getVisibilityDefault = ->
      switch getGroupType()
        when 'educational'  then 'visible'
        when 'company'      then 'hidden'
        when 'project'      then 'visible'
        when 'custom'       then 'visible'

    applyDefaults =->
      {Privacy,Visibility} = modal.modalTabs.forms["General Settings"].inputs
      Privacy.setValue getPrivacyDefault()
      Visibility.setValue getVisibilityDefault()

    modalOptions =
      title                          : 'Create a new group'
      height                         : 'auto'
      cssClass                       : "group-admin-modal compose-message-modal admin-kdmodal"
      width                          : 500
      overlay                        : yes
      tabs                           :
        navigable                    : no
        goToNextFormOnSubmit         : yes
        hideHandleContainer          : yes
        callback                     :(formData)=>
          _createGroupHandler.call @, formData
          modal.destroy()
        forms                        :
          "Select group type"        :
            title                    : 'Group type'
            callback                 :(formData)=>
              log "here"
            buttons                  :
              "Next"                 :
                style                : "modal-clean-gray"
                type                 : "submit"
                callback             : -> applyDefaults()
            fields                   :
              "type"                 :
                name                 : "type"
                itemClass            : KDInputRadioGroup
                defaultValue         : "project"
                cssClass             : "group-type"
                radios               : [
                  { title : "University/School", value : "educational"}
                  { title : "Company",           value : "company"}
                  { title : "Project",           value : "project"}
                  { title : "Other",             value : "custom"}
                ]
          "General Settings"         :
            title                    : 'Create a group'
            buttons                  :
              "Save"                 :
                style                : "modal-clean-gray"
                type                 : "submit"
                loader               :
                  color              : "#444444"
                  diameter           : 12
              "Back"                 :
                style                : "modal-cancel"
                callback             : -> modal.modalTabs.showPreviousPane()
            fields                   :
              "Title"                :
                label                : "Title"
                name                 : "title"
                keydown              : (pubInst, event)->
                  @utils.defer =>
                    slug = @utils.slugify @getValue()
                    verifySlug slug


                placeholder          : 'Please enter your group title...'
              "Slug"                 :
                label                : "Slug"
                name                 : "slug"
                blur                 : ->
                  @utils.defer =>
                    slug = @utils.slugify @getValue()
                    verifySlug slug
                keydown              : ->
                  @utils.defer =>
                    slug = @utils.slugify @getValue()
                    verifySlug slug

                defaultValue         : ""
                placeholder          : 'This value will be automatically generated'
              "Description"          :
                label                : "Description"
                type                 : "textarea"
                name                 : "body"
                defaultValue         : ""
                placeholder          : "Please enter a description for your group here..."
              "Privacy"              :
                label                : "Privacy settings"
                itemClass            : KDSelectBox
                type                 : "select"
                name                 : "privacy"
                defaultValue         : "public"
                selectOptions        :
                  Public             : [
                    { title : "Anyone can join",    value : "public" }
                  ]
                  Private            : [
                    { title : "By invitation",       value : "by-invite" }
                    { title : "By access request",   value : "by-request" }
                    { title : "In same domain",      value : "same-domain" }
                  ]
              "Visibility"           :
                label                : "Visibility settings"
                itemClass            : KDSelectBox
                type                 : "select"
                name                 : "visibility"
                defaultValue         : "visible"
                selectOptions        : [
                  { title : "Visible in group listings",    value : "visible" }
                  { title : "Hidden in group listings",     value : "hidden" }
                ]
              # # Group VM should be there for every group
              #
              # "Group VM"             :
              #   label                : "Create a shared server for the group"
              #   itemClass            : KDOnOffSwitch
              #   name                 : "group-vm"
              #   defaultValue         : no
              #
              # # Members VMs are a future feature
              #
              # "Member VM"            :
              #   label                : "Create a server for each group member"
              #   itemClass            : KDOnOffSwitch
              #   name                 : "member-vm"
              #   defaultValue         : no

    modal = new KDModalViewWithForms modalOptions

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

  loadView:(mainView, firstRun = yes, loadFeed = no)->

    if firstRun
      mainView.on "searchFilterChanged", (value) =>
        return if value is @_searchValue
        @_searchValue = Encoder.XSSEncode value
        @_lastSubview.destroy?()
        @loadView mainView, no, yes
      mainView.createCommons()

    @createFeed mainView, loadFeed

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
      @getView().$(".feeder-header span.optional_title").html count
      return no
    if count >= 20 then count = '20+'
    # return if count % 20 is 0 and count isnt 20
    # postfix = if count is 20 then '+' else ''
    count   = 'No' if count is 0
    result  = "#{count} result" + if count isnt 1 then 's' else ''
    title   = "#{result} found for <strong>#{@_searchValue}</strong>"
    @getView().$(".feeder-header").html title

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

    group.on 'MemberAdded', ->
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

        kallback = (modal, err)=>
          modal.modalTabs.forms.invite.buttons.Send.hideLoader()
          return invitationRequestView.showErrorMessage err if err
          new KDNotificationView title:'Invitation sent!'
          invitationRequestView.refresh()
          modal.destroy()

        invitationRequestView.on 'BatchApproveRequests', (formData)->
          group.sendSomeInvitations formData.count, (err)=>
            return invitationRequestView.showErrorMessage err if err
            invitationRequestView.prepareBulkInvitations()
            kallback @batchApprove, err

        invitationRequestView.on 'InviteByEmail', (formData)->
          group.inviteByEmails formData.emails, (err)=>
            kallback @inviteByEmail, err

        invitationRequestView.on 'InviteByUsername', (formData)->
          group.inviteByUsername formData.recipients, (err)=>
            kallback @inviteByUsername, err

        invitationRequestView.on 'RequestIsApproved', (request)->
          request.approveInvitation()

        invitationRequestView.on 'RequestIsDeclined', (request)->
          request.declineInvitation()

        pane.on 'PaneDidShow', ->
          invitationRequestView.refresh()  if pane.tabHandle.isDirty
          pane.tabHandle.markDirty no

    group.on 'NewInvitationRequest', ->
      pane.emit 'NewInvitationActionArrived'
      pane.tabHandle.markDirty()

    return pane

  prepareVocabularyTab:->
    {groupView} = this
    group = groupView.getData()
    pane = groupView.createLazyTab 'Vocabulary', GroupsVocabulariesView,
      (pane, vocabView)->

        group.fetchVocabulary (err, vocab)-> vocabView.setVocabulary vocab

        vocabView.on 'VocabularyCreateRequested', ->
          {JVocabulary} = KD.remote.api
          JVocabulary.create {}, (err, vocab)->
            vocabView.setVocabulary vocab

  createContentDisplay:(group, callback)->

    @groupView = groupView = new GroupView
      cssClass : "group-content-display"
      delegate : @getView()
    , group

    @prepareReadmeTab()
    @prepareSettingsTab()
    @preparePermissionsTab()
    @prepareMembersTab()
    @prepareVocabularyTab()

    if 'private' is group.privacy
      @prepareMembershipPolicyTab()
      @prepareInvitationsTab()

    contentDisplay = @showContentDisplay @groupView
    callback? contentDisplay


  showContentDisplay:(groupView)->
    contentDisplayController = @getSingleton "contentDisplayController"
    contentDisplayController.emit "ContentDisplayWantsToBeShown", groupView
    groupView.on 'PrivateGroupIsOpened', @bound 'openPrivateGroup'
    return groupView

  loginRequired:(callback)->
    new KDNotificationView
      type     : 'mini'
      cssClass : 'error'
      title    : 'Login is required for this action'
      duration : 5000

    route = "/#{KD.groupEntryPoint}/Login" if KD.groupEntryPoint isnt ''
    @getSingleton('router').handleRoute route
    @getSingleton('mainController').once 'AccountChanged', ->
      if KD.isLoggedIn()
        callback()

  # old load view
  # loadView:(mainView, firstRun = yes)->

  #   if firstRun
  #     mainView.on "searchFilterChanged", (value) =>
  #       return if value is @_searchValue
  #       @_searchValue = Encoder.XSSEncode value
  #       @_lastSubview.destroy?()
  #       @loadView mainView, no

  #     mainView.createCommons()

  #   KD.whoami().fetchRole? (err, role) =>
  #     if role is "super-admin"
  #       @listItemClass = GroupsListItemViewEditable
  #       if firstRun
  #         @getSingleton('mainController').on "EditPermissionsButtonClicked", (groupItem)=>
  #           @editPermissions groupItem
  #         @getSingleton('mainController').on "EditGroupButtonClicked", (groupItem)=>
  #           groupData = groupItem.getData()
  #           groupData.canEditGroup (err, hasPermission)=>
  #             unless hasPermission
  #               new KDNotificationView title: 'Access denied'
  #             else
  #               @showGroupSubmissionView groupData
  #         @getSingleton('mainController').on "MyRolesRequested", (groupItem)=>
  #           groupItem.getData().fetchRoles console.log.bind console

  #     @createFeed mainView
  #   # mainView.on "AddATopicFormSubmitted",(formData)=> @addATopic formData
