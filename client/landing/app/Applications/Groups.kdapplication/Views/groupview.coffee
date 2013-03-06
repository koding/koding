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

    @staleTabs = []
    @createTabs()

  createLazyTab:(tabName, konstructor, options, initializer)->
    if 'function' is typeof options
      initializer = options 
      options = {}

    pane = new KDTabPaneView name: tabName
    pane.once 'PaneDidShow', =>
      view = new konstructor options ? {}, @getData()
      pane.addSubView view
      initializer?.call? pane, pane, view

    @tabView.addPane pane, no

    return pane


  # assureTab:(tabName, showAppend=yes, konstructor, options, initializer)->
  #   if 'function' is typeof options
  #     initializer = options
  #     options = {}

  #   pane = @tabView.getPaneByName tabName

  #   # if the pane is not there yet, create it an populate with views
  #   unless pane
  #     view = new konstructor options ? {}, @getData()
  #     pane = new KDTabPaneView name: tabName
  #     initializer?.call? pane, pane, view
  #     @tabView.addPane pane, showAppend
  #     pane.addSubView view

  #   # if the view is there and stale, remove the views and 'refresh'
  #   else if @isStaleTab tabName
  #     pane.getSubViews().forEach (view)->
  #       pane.removeSubView view
  #     view = new konstructor options ? {}, @getData()
  #     pane.addSubView view
  #     @unsetStaleTab tabName

  #   # in any case: show the pane if it is hidden and should be shown
  #   if showAppend and @tabView.getActivePane() isnt pane
  #     @tabView.showPane pane
  #   return pane

  setStaleTab:(tabName)->
    @staleTabs.push tabName unless @staleTabs.indexOf(tabName) > -1

  unsetStaleTab:(tabName)->
    @staleTabs.splice @staleTabs.indexOf(tabName), 1

  isStaleTab:(tabName)->
    @staleTabs.indexOf(tabName) > -1

  createTabs:->
    data = @getData()

    @tabView = new KDTabView
      cssClass : 'group-content'
      hideHandleContainer : yes
      hideHandleCloseIcons : yes
      tabHandleView : GroupTabHandleView
    , data
    @utils.defer => @emit 'ReadmeSelected'

  decorateUponRoles:(roles)->

    if "admin" in roles
      @tabView.showHandleContainer()

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
