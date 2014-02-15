class ActivityRightBase extends JView

  constructor:(options={}, data)->

    super options, data

    @tickerController = new KDListViewController
      startWithLazyLoader : yes
      lazyLoaderOptions   : partial : ''
      viewOptions         :
        type              : "activities"
        cssClass          : "activities"
        itemClass         : @itemClass

    @tickerListView = @tickerController.getView()


  renderItems: (err, items=[])->

    @tickerController.hideLazyLoader()
    @tickerController.addItem item for item in items  unless err


  pistachio:->
    """
    <div class="right-block-box">
      <h3>#{@getOption 'title'}{{> @showAllLink}}</h3>
      {{> @tickerListView}}
    </div>
    """

class ActiveUsers extends ActivityRightBase

  constructor:(options={}, data)->
    {entryPoint} = KD.config
    if entryPoint?.type is "group" then group = entryPoint.slug else group = "koding"

    @itemClass       = MembersListItemView
    options.title    = if group is "koding" then "Active users" else "New Members"
    options.cssClass = "active-users"

    super options, data

    @showAllLink = new KDCustomHTMLView
      tagName : "a"
      partial : "show all"
      cssClass: "show-all-link hidden"
      click   : (event) ->
        KD.singletons.router.handleRoute "/Members"
        KD.mixpanel "Show all members, click"
    , data

    if group is "koding"
      KD.remote.api.ActiveItems.fetchUsers {}, @bound 'renderItems'
    else
      KD.singletons.groupsController.ready =>
        currentGroup = KD.singletons.groupsController.getCurrentGroup()
        currentGroup.fetchNewestMembers {}, "limit" : 10, @bound 'renderItems'


class ActiveTopics extends ActivityRightBase

  constructor:(options={}, data)->

    @itemClass       = ActiveTopicItemView
    options.title    = "Popular topics"
    options.cssClass = "active-topics"

    super options, data

    @showAllLink = new KDCustomHTMLView

    {entryPoint} = KD.config
    if entryPoint?.type is "group" then group = entryPoint.slug else group = "koding"

    @showAllLink = new KDCustomHTMLView
      tagName : "a"
      partial : "show all"
      cssClass: "show-all-link"
      click   : (event) ->
        if group is "koding" then route = "/Topics" else route = "/#{group}/Topics"
        KD.singletons.router.handleRoute route
        KD.mixpanel "Show all topics, click"
    , data

    if group is "koding"
      KD.remote.api.ActiveItems.fetchTopics {group}, @bound 'renderItems'
    else
      KD.remote.api.JTag.some {group},
        limit  : 16
        sort   : "counts.followers" : -1
      , @bound 'renderItems'


class GroupDescription extends KDView

  constructor:(options={}, data)->
    super options, data

    {groupsController} = KD.singletons
    groupsController.ready =>
      group = groupsController.getCurrentGroup()

      @innerContaner = new KDCustomHTMLView cssClass : "right-block-box"

      @titleView = new KDCustomHTMLView
        tagName   : "h3"
        pistachio : "{{ #(title)}}"
      , group

      @bodyView = new KDCustomHTMLView
        tagName   : "p"
        pistachio : "{{ #(body)}}"
        cssClass  : "group-description"
      , group



      @innerContaner.addSubView @titleView
      @innerContaner.addSubView @bodyView
      @addSubView @innerContaner

      if "admin" in KD.config.roles
        hasBody = group.body.trim() isnt ""
        @bodyView.setPartial "You can have a short description for your group here"  unless hasBody
        @bodyView.setPartial " - "
        @bodyView.addSubView new CustomLinkView
          title    : if hasBody then "edit" else "Add a description"
          click    : (event)->
            KD.utils.stopDOMEvent event
            KD.singletons.router.handleRoute "/Dashboard"


class GroupMembers extends ActivityRightBase

  constructor:(options={}, data)->
    @itemClass       = GroupMembersListItemView
    options.title    = "Group members"
    options.cssClass = "group-members"

    super options, data

    {entryPoint} = KD.config
    if entryPoint?.type is "group" then groupSlug = entryPoint.slug else groupSlug = "koding"

    @showAllLink = new KDCustomHTMLView
      tagName    : "a"
      partial    : "See All"
      cssClass   : "show-all-link"
      click      : (event) ->
        KD.singletons.router.handleRoute "/#{groupSlug}/Members"
        KD.mixpanel "Show all members, click"
    , @getData()

    {groupsController} = KD.singletons
    groupsController.ready =>
      group = groupsController.getCurrentGroup()
      group.fetchMembers {}, limit : 12, (err, members) =>
        @renderItems err, members
        if members.length < 12
          groupsController.on "MemberJoinedGroup", (data) =>
            {constructorName, id} = data.member
            KD.remote.cacheable constructorName, id, (err, account)=>
              return console.error "account is not found", err if err or not account
              @tickerController.addItem account




class GroupMembersListItemView extends KDListItemView

  constructor: (options = {}, data) ->
    super options, data
    @avatar      = new AvatarView
      size       : width : 60, height : 60
      showStatus : yes
    , @getData()
    @addSubView @avatar

  viewAppended:JView::viewAppended
