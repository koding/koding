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

  assureTab:(tabName, konstructor, options={})->
    pane = @tabView.panes[tabName]
    unless pane?
      view = new konstructor options, @getData()
      pane = new KDTabPaneView name: tabName
      @tabView.addPane pane
      pane.addSubView view
    @tabView.showPane pane
    return pane

  createTabs:->
    data = @getData()

    @tabView = new KDTabView
      hideHandleContainer : yes
    , data

    @tabView.addPane readmeTab = new KDTabPaneView
    readmeTab.addSubView new GroupReadmeView {}, data

  decorateUponRoles:(roles)->

    if "admin" in roles
      @adminMenuLink = new CustomLinkView
        cssClass    : 'fr'
        title       : "Admin"
        icon        :
          cssClass  : 'admin'
        click       : (event)=>
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
            'Settings'              :
              callback              : (source, event)=>
                @emit 'SettingsSelected'
                contextMenu.destroy()
              separator             : yes
            'Permissions'           :
              callback              : (source, event)=>
                @emit 'PermissionsSelected'
                contextMenu.destroy()
            'Members'               :
              callback              : (source, event)=>
                @emit 'MembersSelected'
                contextMenu.destroy()
            'Membership policy'     :
              callback              : (source, event)=>
                @emit 'MembershipPolicySelected'
                contextMenu.destroy()

      @addSubView @adminMenuLink, ".navbar"


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
