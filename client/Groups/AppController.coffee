class GroupsAppController extends AppController

  KD.registerAppClass this,
    name         : "Groups"
    route        : "/Groups"
    hiddenHandle : yes
    # navItem      :
    #   title      : "Groups"
    #   path       : "/Groups"
    #   order      : 40
    #   topLevel   : yes
    preCondition :
      condition  : (options, cb)-> cb KD.checkFlag "group-admin"
      failure    : -> KD.getSingleton('router').handleRoute "/Activity"

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
    @controllers   = {}
    @isReady       = no
    KD.getSingleton('windowController').on "FeederListViewItemCountChanged", (count, itemClass, filterName)=>
      if @_searchValue and itemClass is @listItemClass then @setCurrentViewHeader count

  onboardingText =
    everything : """
      <h3 class='title'>Koding groups are a simple way to connect and interact with people who share
      your interests.</h3>

      <p>When you join a group such as your univeristy or your company, you can share virtual
      machines, collaborate on projects and stay up to date on the activites of others in your
      group.</p>

      <h3 class='title'>Easy to get started</h3>

      <p>Groups are free to create. You decide who can join, what actions they can do inside the
      group and what they see.</p>
      """
    pending   : """
      <h3 class='title'>Groups that you are waiting for an invitation will be listed here.</h3>
      <p>When you ask for an invitation to a group, an admin of that group should accept your request and send you an invitation link in order you to gain access to that group.</p>
      """
    requested : """
      <h3 class='title'>These are the groups that you requested access...</h3>
      <p>...but still waiting for a group admin to approve.</p>
      <p>When you request access to a group, an admin of that group should accept your request. If the admin approves you'll gain access to the group right away and you'll see it under 'My Groups'.</p>
      """

  createFeed:(view, loadFeed = no)->

    KD.getSingleton("appManager").tell 'Feeder', 'createContentFeedController', {
      feedId                : 'groups.main'
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
        everything          : onboardingText.everything
        pending             : onboardingText.pending
        requested           : onboardingText.requested
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
                  ids = (item.getId?() for item in items)
                  callback null, null, ids
            else
              JGroup.streamModels selector, options, callback
          dataEnd           :({resultsController}, ids)=>
            {everything} = resultsController.listControllers
            @markGroupRelationship everything, ids
          dataError         :(controller, err)->
            log "Seems something broken:", controller, err

        mine                :
          title             : "My groups"
          loggedInOnly      : yes
          dataSource        : (selector, options, callback)=>
            KD.whoami().fetchGroups options, (err, items)=>
              ids = []
              for item in items
                item.followee = true
                ids.push item.group.getId()
              callback err, (item.group for item in items)
              callback err, null, ids
          dataEnd           :({resultsController}, ids)=>
            {mine} = resultsController.listControllers
            @markGroupRelationship mine, ids

        pending             :
          title             : "Invitation pending"
          loggedInOnly      : yes
          dataSource        : (selector, options, callback)=>
            KD.whoami().fetchGroupsWithPendingInvitations options, (err, groups)->
              callback err, groups
              callback err, null, (group.getId() for group in groups)
          dataEnd           :({resultsController}, ids)=>
            {pending} = resultsController.listControllers
            @markPendingGroupInvitations pending, ids

        requested             :
          title             : "Request pending"
          loggedInOnly      : yes
          dataSource        : (selector, options, callback)=>
            KD.whoami().fetchGroupsWithPendingRequests options, (err, groups)->
              callback err, groups
              callback err, null, (group.getId() for group in groups)
          dataEnd           :({resultsController}, ids)=>
            {requested} = resultsController.listControllers
            @markPendingRequestGroups requested, ids

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
      @emit 'ready'

      KD.mixpanel "Group list load, success"

  markGroupRelationship:(controller, ids)->
    fetchRoles =
      member: (view)-> view.markMemberGroup()
      admin : (view)-> view.markGroupAdmin()
      owner : (view)-> view.markOwnGroup()
    for own as, callback of fetchRoles
      do (as, callback)->
        KD.remote.api.JGroup.fetchMyMemberships ids, as, (err, groups)->
          return error err if err
          controller.forEachItemByIndex groups, callback

    KD.whoami().fetchGroupsWithPendingRequests groupIds:ids, (err, groups)=>
      @markPendingRequestGroups controller, (group.getId() for group in groups)

    KD.whoami().fetchGroupsWithPendingInvitations groupIds:ids, (err, groups)=>
      @markPendingGroupInvitations controller, (group.getId() for group in groups)

  forEachItemByIndex:(controller, ids, callback)->
    [callback, ids] = [ids, callback]  unless callback
    ids = [ids]  unless Array.isArray ids
    ids.forEach (id)=>
      item = controller.itemsIndexed[id]
      callback item  if item?

  markPendingRequestGroups:(controller, ids)->
    @forEachItemByIndex controller, ids, (view)-> view.markPendingRequest()

  markPendingGroupInvitations:(controller, ids)->
    @forEachItemByIndex controller, ids, (view)-> view.markPendingInvitation()

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
      KD.getSingleton('staticGroupController')?.emit 'AccessIsRequested', group

  showRequestAccessModal:(group, policy, callback=->)->

    if policy.explanation
      title   = "Request Access"
      content = utils.applyMarkdown policy.explanation
      success = "Your request has been sent to the group's admin."
    else if policy.approvalEnabled
      title   = 'Request Access'
      content = 'Membership to this group requires administrative approval.'
      success = "Thanks! You'll be notified when group's admin accepts you."
    else
      title   = 'Request an Invite'
      content = 'Membership to this group requires an invitation.'
      success = "Your request has been sent to the group's admin."

    modal = new KDModalView
      title          : title
      overlay        : yes
      width          : 300
      height         : 'auto'
      content        : "<div class='modalformline'><p>#{content}</p></div>"
      buttons        :
        request      :
          title      : title
          testPath   : "groups-request-button"
          loader     :
            color    : "#ffffff"
            diameter : 12
          style      : 'modal-clean-green'
          callback   : (event)->
            group.requestAccess (err)->
              modal.buttons.request.hideLoader()
              if err
                KD.showError err
                return callback err

              new KDNotificationView title: success
              modal.destroy()
              callback null

  openPrivateGroup:(group)->
    group.canOpenGroup (err, hasPermission)=>
      if err
        @showErrorModal group, err
      else if hasPermission
        @openGroup group

  _createGroupHandler =(formData, callback)->

    if formData.privacy in ['by-invite', 'by-request', 'same-domain']
      formData.requestType = formData.privacy
      formData.privacy     = 'private'

    KD.remote.api.JGroup.create formData, (err, { group })=>
      if err
        callback? err
        new KDNotificationView
          title: err.message
          duration: 1000
      else
        callback no
        @showGroupCreatedModal group

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

  showGroupSubmissionView:-> new GroupCreationModal

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
      #   KD.getSingleton('windowManager').open @href, slug

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

  createContentDisplay:(group, callback)->

    unless KD.config.roles? and 'admin' in KD.config.roles
      routeSlug = if group.slug is KD.defaultSlug then '/' else "/#{group.slug}/"
      return KD.getSingleton('router').handleRoute "#{routeSlug}Activity"

    @groupView = groupView = new GroupView
      cssClass : "group-content-display"
      delegate : @getView()
    , group

    @prepareReadmeTab()
    @prepareSettingsTab()
    @preparePermissionsTab()
    @prepareMembersTab()
    # @prepareBundleTab()
    # @prepareVocabularyTab()

    if 'private' is group.privacy
      @prepareMembershipPolicyTab()
      @prepareInvitationsTab()

    contentDisplay = @showContentDisplay @groupView
    callback? contentDisplay


  showContentDisplay:(groupView)->

    KD.singleton('display').emit "ContentDisplayWantsToBeShown", groupView
    groupView.on 'PrivateGroupIsOpened', @bound 'openPrivateGroup'
    return groupView

  showGroupCreatedModal:(group)->
    group.fetchMembershipPolicy (err, policy)=>
      return new KDNotificationView title: 'An error occured, however your group has been created!' if err

      @feedController.reload() if @feedController

      groupUrl    = "//#{location.host}/#{group.slug}"
      privacyExpl = if group.privacy is 'public'
      then 'Koding users can join anytime without approval'
      else if policy.invitationsEnabled
      then 'and only invited users can join'
      else 'Koding users can only join with your approval'

      body  = """
        <div class="modalformline">Your group can be accessed via <a id="go-to-group-link" class="group-link" href="#{groupUrl}" target="#{group.slug}">#{location.protocol}#{groupUrl}</a></div>
        <div class="modalformline">It is <strong>#{group.visibility}</strong> in group listings.</div>
        <div class="modalformline">It is <strong>#{group.privacy}</strong>, #{privacyExpl}.</div>
        <div class="modalformline">You can manage your group settings from the group dashboard anytime.</div>
        <a id="go-to-dashboard-link" class="hidden" href="#{groupUrl}/Dashboard" target="#{group.slug}">#{groupUrl}/Dashboard</a>
        """
      modal = new KDModalView
        title        : "#{group.title} has been created!"
        content      : body
        testPath     : "groups-create-confirm"
        buttons      :
          dashboard  :
            title    : 'Go to Dashboard'
            style    : 'modal-clean-green'
            callback : ->
              document.getElementById('go-to-dashboard-link').click()
              modal.destroy()
          group      :
            title    : 'Go to Group'
            style    : 'modal-clean-gray'
            callback : ->
              document.getElementById('go-to-group-link').click()
              modal.destroy()
          dismiss    :
            title    : 'Dismiss'
            style    : 'modal-cancel'
            callback : -> modal.destroy()
