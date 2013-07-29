class HomeFeaturedActivitiesView extends JView
  constructor:(options,data)->
    super options,data

    @activityController = new KDListViewController
      view            : @recentActivities = new KDListView
        lastToFirst   : no
        itemClass     : HomeActivityItem

    KD.getSingleton("appManager").tell "Activity", "fetchFeedForHomePage", {limit:10}, (err,activity)=>
      if activity
        @activityController.instantiateListItems activity

    @headline = new KDView
      partial : 'Recent Activity'
      cssClass : 'featured-header'

    @setClass 'activity-related'
  pistachio:->
    """
    {{> @headline}}
    {{> @recentActivities}}
    """

class HomeFeaturedMembersView extends JView

  constructor:(options, data)->

    super options, data
    @loader         = new KDLoaderView
      size          :
        width       : 30
      loaderOptions :
        color       : '#aaaaaa'

    membersController = new KDListViewController
      view         : @members = new KDListView
        wrapper    : no
        scrollView : no
        type       : "members"
        itemClass  : GroupItemMemberView
        itemChildOptions:
          avatarWidth  :160
          avatarHeight :160
    KD.remote.cacheable 'koding', (err,group)=>
      group.first.fetchNewestMembers {},
        limit      : 16
      ,(err, members)=>
        if err then warn err
        else if members
          @loader.hide()
          @$('.members-list-wrapper').removeClass "hidden"
          membersController.instantiateListItems members

    @utils.defer => @loader.show()

  pistachio:->
    """
      <div class="featured-header">Latest Members</div>
      {{> @loader}}
      {{> @members}}
    """

class HomeFeaturedAppsView extends JView

  constructor:(options, data)->

    super options, data

    appsController = new KDListViewController
      view         : @apps = new KDListView
        wrapper    : no
        scrollView : no
        type       : "apps"
        itemClass  : HomeFeaturedAppsListItemView
        itemChildOptions:
          avatarWidth  :250
          avatarHeight :250

    KD.remote.api.JApp.some {},{limit:4},(err,apps)=>
      if err then warn err
      else if apps
        appsController.instantiateListItems apps
  pistachio:->
    """
     <div class="featured-header">Latest Apps</div>
     {{> @apps}}
    """

class HomeFeaturedAppsListItemView extends KDListItemView
  constructor:(options,data)->
    super options,data
    {icns, name, identifier, version, authorNick} = @getData().manifest
    if icns and (icns['256'] or icns['512'] or icns['128'] or icns['160'] or icns['64'])
      thumb = "#{KD.appsUri}/#{authorNick}/#{identifier}/#{version}/#{if icns then icns['256'] or icns['128'] or icns['160'] or icns['512'] or icns['64']}"
    else
      thumb = "#{KD.apiUri + '/images/default.app.listthumb.png'}"

    @thumbnail = new KDCustomHTMLView
      tagName     : "img"
      bind        : "error"
      error       : =>
        @thumbnail.$().attr "src", "/images/default.app.listthumb.png"
      attributes  :
        src       : thumb

    @name = new KDView
      partial : name
      cssClass : 'app-name'

    @followers = new KDView
      cssClass : 'app-followers'
      partial : "Followers: #{@getData().counts.followers}"

    @installed = new KDView
      cssClass : 'app-installed'
      partial : "Installed: #{@getData().counts.installed}"

  showDetailModal:->
    modal = new KDModalView
      title : @getData().manifest.name
      width : 600
      view : new HomeFeaturedAppsDetailsView
          cssClass : 'featured-app-details'
          delegate : @
        , @getData()
    @on 'ModalShouldClose', => modal.destroy()

  click:->
    @showDetailModal()

  viewAppended:->
    super
    @setTemplate @pistachio()
    @template.update()


  pistachio:->
    """
    {{> @thumbnail}}
    <div class="details">
      {{> @name}}
      <div class="counts">
        <div class="followers-wrapper">
          {{> @followers}}
        </div>
        <div class="installed-wrapper">
          {{> @installed}}
        </div>
      </div>
    </div>
    """

class HomeFeaturedAppsDetailsView extends JView

  constructor:(options, data)->

    super options, data

    {manifest,slug,counts,meta} = @getData()

    log @getData()

    {icns, name, identifier, version, authorNick, description, author} = manifest

    if icns and (icns['256'] or icns['512'] or icns['128'] or icns['160'] or icns['64'])
      thumb = "#{KD.appsUri}/#{authorNick}/#{identifier}/#{version}/#{if icns then icns['256'] or icns['128'] or icns['160'] or icns['512'] or icns['64']}"
    else
      thumb = "#{KD.apiUri + '/images/default.app.listthumb.png'}"

    @thumbnail = new KDCustomHTMLView
      cssClass    : 'details-thumb'
      tagName     : "img"
      bind        : "error"
      error       : =>
        @thumbnail.$().attr "src", "/images/default.app.listthumb.png"
      attributes  :
        src       : thumb

    @name = new KDView
      cssClass : 'details-name'
      partial : name

    @author = new KDView
      cssClass : 'details-author'
      partial : "by #{author}"

    @version = new KDView
      cssClass : 'details-version'
      partial : "version #{version}"

    @description = new KDView
      cssClass : 'details-description'
      partial : description

    @likes = new KDView
      cssClass : 'details-likes'
      partial : "Likes: #{meta.likes}"

    @followers = new KDView
      cssClass : 'details-followers'
      partial : "Followers: #{counts.followers}"

    @installed = new KDView
      cssClass : 'details-installed'
      partial : "Installed: #{counts.installed}"

    @installButton = new KDButtonView
      title : "Install this app"
      cssClass : "cupid-green details-install-button"
      callback :=>
        # if KD.isLoggedIn()
        KD.getSingleton('router').handleRoute "/Apps/#{slug}", state:@getData()
        @getDelegate().emit "ModalShouldClose"
        # else
        #   KD.getSingleton('router').handleRoute "/Login", state:@getData()
        #   @getDelegate().emit "ModalShouldClose"

  pistachio:->
    """
      <div class="sidebar">
        {{> @thumbnail}}
        {{> @installButton}}
      </div>
      <div class="content">
      {{> @name}}
      {{> @version}}
      {{> @author}}
      {{> @description}}
      <div class="counts">
        {{> @followers}}
        {{> @installed}}
        {{> @likes}}
      </div>
      </div>
    """

class HomeActivityItem extends ActivityListItemView
  constructor:->
    super

  viewAppended:->
    super
    @utils.defer =>
      # remove interactive subviews
      @getSubViews().first?.commentBox.destroy()
      @getSubViews().first?.actionLinks.destroy()
      @getSubViews().first?.settingsButton.destroy()

  pistachio:->
    super