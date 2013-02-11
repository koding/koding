class GroupView extends ActivityContentDisplay

  constructor:->

    super

    data = @getData()

    @thumb = new KDCustomHTMLView
      tagName     : "img"
      bind        : "error"
      error       : =>
        @thumb.$().attr "src", "/images/default.app.thumb.png"
      attributes  :
        src       : @getData().avatar or "http://lorempixel.com/60/60/?#{@utils.getRandomNumber()}}"

    @joinButton = new JoinButton
      style           : if data.member then "join follow-btn following-topic" else "join follow-btn"
      title           : "Join"
      dataPath        : "member"
      defaultState    : if data.member then "Leave" else "Join"
      loader          :
        color         : "#333333"
        diameter      : 18
        top           : 11
      states          : [
        "Join", (callback)->
          data.join (err, response)=>
            console.log arguments
            @hideLoader()
            unless err
              @emit 'Joined'
              @setClass 'following-btn following-topic'
              callback? null
        "Leave", (callback)->
          data.leave (err, response)=>
            console.log arguments
            @hideLoader()
            unless err
              @emit 'Left'
              @unsetClass 'following-btn following-topic'
              callback? null
      ]
    , data

    {slug, privacy} = data

    @enterLink = new CustomLinkView
      cssClass    : 'enter-group'
      href        : "/#{slug}/Activity"
      target      : slug
      title       : 'Open group'
      click       : if privacy is 'private' then @bound 'privateGroupOpenHandler'
      icon        :
        placement : "right"
        cssClass  : "enter-group"

    @joinButton.on 'Joined', @enterLink.bound "show"

    @joinButton.on 'Left', @enterLink.bound "hide"

    {JGroup} = KD.remote.api

    JGroup.fetchMyMemberships data.getId(), (err, groups)=>
      if err then error err
      else
        if data.getId() in groups
          @joinButton.setState 'Leave'
          @joinButton.redecorateState()

    data.fetchMyRoles (err, roles)=>
      if err then error err
      else
        @decorateUponRoles roles
          # @enterButton.show()
    # @homeLink = new KDCustomHTMLView
    #   tagName     : 'a'
    #   attributes  :
    #     href      : data.slug
    #   pistachio   : "Enter {{#(title)}}"
    #   click       : (event)->
    #     # debugger
    #     event.stopPropagation()
    #     event.preventDefault()
    #     KD.getSingleton('router').handleRoute "/#{data.slug}/Activity"
    # , data

    @createTabs()

  createTabs:->
    data = @getData()

    @tabView = new KDTabView
      hideHandleContainer : yes
    , data

    @tabView.addPane @readmeTab = new KDTabPaneView
    @readmeTab.addSubView new GroupReadmeView {}, data

  decorateUponRoles:(roles)->

    if "admin" in roles
      @adminMenuLink = new CustomLinkView
        cssClass    : 'fr'
        title       : "Admin"
        icon        :
          cssClass  : 'admin'
        click       : (event)=>
          event.preventDefault()
          contextMenu = new JContextMenu
            cssClass    : "group-admin-menu"
            event       : event
            delegate    : @adminMenuLink
            offset      :
              top       : 10
              left      : -30
            arrow       :
              placement : "top"
              margin    : -20
          ,
            'Settings'             :
              callback             : (source, event)=> 
                unless @settingsTab 
                  @tabView.addPane @settingsTab = new KDTabPaneView
                  @settingsTab.addSubView new GroupGeneralSettingsView {}, @getData()               
                @tabView.showPane @settingsTab

                contextMenu.destroy()
              separator            : yes
            'Permissions'          :
              callback             : (source, event)=>   
                unless @permissionTab 
                  @tabView.addPane @permissionTab = new KDTabPaneView
                  @permissionTab.addSubView new GroupPermissionView {}, @getData()               
                @tabView.showPane @permissionTab
                contextMenu.destroy()
            'Readme'      :
              callback             : (source, event)=> 
                @tabView.showPane @readmeTab
                contextMenu.destroy()
            'Member Roles'      :
              callback             : (source, event)=> 
                unless @memberTab 
                  @tabView.addPane @memberTab = new KDTabPaneView
                  @memberTab.addSubView new GroupsMemberPermissionsView {}, @getData()               
                @tabView.showPane @memberTab

                contextMenu.destroy()
            

            'Membership Policies'          :
              callback             : (source, event)=> 
                unless @membershipPolicyTab

                  @membershipPolicyTabView = new KDTabView
                    hideHandleContainer : no
                  , @getData()

                  @tabView.addPane @membershipPolicyTab = new KDTabPaneView
                  
                  if @getData().privacy is 'private'
                    @getData().fetchMembershipPolicy (err, policy)=>
                      membershipPolicyView = new GroupsMembershipPolicyView {}, policy

                      membershipPolicyView.on 'MembershipPolicyChanged', (data)->
                        @getData().modifyMembershipPolicy data, ->
                          membershipPolicyView.emit 'MembershipPolicyChangeSaved'
                      
                      @membershipPolicyTabView.addPane @policyTab = new KDTabPaneView
                        name : 'Membership Policies'
                      
                      @policyTab.addSubView membershipPolicyView
                      
                      @membershipPolicyTabView.showPane @policyTab
                      @membershipPolicyTab.addSubView @membershipPolicyTabView
                      if policy.invitationsEnabled
                        @showInvitationsTab @getData(), @membershipPolicyTabView
                      else if policy.approvalEnabled
                        @showApprovalTab @getData(), @membershipPolicyTabView

                @tabView.showPane @membershipPolicyTab
                contextMenu.destroy()

      @addSubView @adminMenuLink, ".navbar"

  
  showInvitationsTab:(group, tabView)->
    @invitationTab = new KDTabPaneView 
      name: 'Invitations'
      shouldShow:no
    tabView.addPane @invitationTab, no

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
    
    @invitationTab.addSubView invitationRequestView


  showApprovalTab:(group, tabView)->
    console.log 'show approval tab', {tabView}


  privateGroupOpenHandler: GroupsAppController.privateGroupOpenHandler

  viewAppended: JView::viewAppended

  pistachio:->
    """
    <h2 class="sub-header">{{> @back}}</h2>
    <div class='group-header'>
      <div class='avatar'>
        <span>{{> @thumb}}</span>
      </div>
      <section class="right-overflow">
        {h2{#(title)}}
        <div class="buttons">
          {{> @joinButton}}
        </div>
      </section>
      <div class="navbar clearfix">
        {{> @enterLink}}
      </div>
      <div class='desc#{if @getData().body is '' then ' hidden' else ''}'>
        {p{#(body)}}
      </div>
    </div>
    {{> @tabView}}
    """
