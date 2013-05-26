class AppView extends KDView

  constructor:(options, data)->

    super

    app = @getData()

    @followButton = new KDToggleButton
      style           : "kdwhitebtn"
      dataPath        : "followee"
      defaultState    : "Follow"
      states          : [
        title         : "Follow"
        callback      : (cb)->
          KD.requireLogin
            callback  : => app.follow (err)-> cb? err
            onFailMsg : "Login required to follow Apps"
            tryAgain  : yes
      ,
        title         : "Unfollow"
        callback      : (callback)->
          app.unfollow (err)->
            callback? err
      ]
    , app

    @likeButton = new KDToggleButton
      style           : "kdwhitebtn"
      defaultState    : 'Like'
      states          : [
        title         : "Like"
        callback      : (cb)->
          KD.requireLogin
            callback  : => app.like (err)-> cb? err
            onFailMsg : "Login required to like Apps"
            tryAgain  : yes
      ,
        title         : "Unlike"
        callback      : (callback)->
          app.like (err)->
            callback? err
      ]
    , app

    if KD.isLoggedIn()
      KD.whoami().isFollowing? app.getId(), "JApp", (err, following) =>
        app.followee = following
        @followButton.setState "Unfollow"  if following

    appsController = @getSingleton("kodingAppsController")

    if KD.checkFlag 'super-admin'
      @approveButton = new KDToggleButton
        style           : "kdwhitebtn"
        dataPath        : "approved"
        defaultState    : if app.approved then "Disapprove" else "Approve"
        states          : [
          title         : "Approve"
          callback      : (callback)->
            app.approve yes, (err)->
              if err then warn err
              callback? err
        ,
          title         : "Disapprove"
          callback      : (callback)->
            app.approve no, (err)-> callback? err
        ]
      , app

      @removeButton = new KDButtonView
        title    : "Delete"
        style    : "kdwhitebtn"
        callback : =>
          modal = new KDModalView
            title          : "Delete App"
            content        : "<div class='modalformline'>Are you sure you want to delete this application?</div>"
            height         : "auto"
            overlay        : yes
            buttons        :
              Delete       :
                style      : "modal-clean-red"
                loader     :
                  color    : "#ffffff"
                  diameter : 16
                callback   : =>
                  app.delete (err)=>
                    modal.buttons.Delete.hideLoader()
                    modal.destroy()
                    if not err
                      @emit 'AppDeleted', app
                      KD.getSingleton("appManager").open "Apps", yes, (instance)=>
                        @utils.wait 100, instance.feedController.changeActiveSort "meta.modifiedAt"
                        callback?()
                    else
                      new KDNotificationView
                        type     : "mini"
                        cssClass : "error editor"
                        title    : "Error, please try again later!"
                      warn err

    else
      @approveButton = new KDView
      @removeButton  = new KDView

    if KD.isLoggedIn() then app.checkIfLikedBefore (err, likedBefore)=>
      if likedBefore
        @likeButton.setState "Unlike"
      else
        @likeButton.setState "Like"

    if app.versions?.length > 1 and KD.isLoggedIn()
      menu = {}

      for version,i in app.versions
        menu["Install version #{version}"] =
          version  : version
          callback : (item)=>
            {version} = item.data
            version   = 'latest' if app.versions.last is item.data.version
            appsController.installApp app, version, (err)=>
              if err then warn err

      @installButton = new KDButtonViewWithMenu
        title     : "Install Now"
        style     : "cupid-green"
        loader    :
          top     : 0
          diameter: 30
          color   : "#ffffff"
        delegate  : @
        menu      : menu
        callback  : ->
          appsController.installApp app, 'latest', (err)=>
            @hideLoader()

    else
      @installButton = new KDButtonView
        title     : "Install Now"
        style     : "cupid-green"
        loader    :
          top     : 0
          diameter: 30
          color   : "#ffffff"
        callback  : ->
          appsController.installApp app, 'latest', (err)=>
            @hideLoader()

    @openButton = new KDButtonView
      title     : "Open"
      style     : "cupid-green"
      callback  : =>
        @getSingleton("appManager").open app.title

    @openButton.hide()

    @updateButton = new KDButtonView
      title       : "Update"
      style       : "clean-gray"
      callback    : =>
        appsController.updateUserApp app.manifest, ->
          @getSingleton("router").handleRoute "Develop"

    appsController.fetchApps (err, manifests) =>
      # user have the app, show just show open button
      if app.title in Object.keys manifests
        @installButton.hide()
        @openButton.show()

      appName   = app.manifest.name
      {version} = manifests[appName]
      unless appsController.isAppUpdateAvailable appName, version
        @updateButton.hide()


    {icns, name, version, authorNick} = app.manifest
    thumb = if icns and (icns['256'] or icns['512'] or icns['128'] or icns['160'] or icns['64'])
      "#{KD.appsUri}/#{authorNick}/#{name}/#{version}/#{if icns then icns['256'] or icns['512'] or icns['128'] or icns['160'] or icns['64']}"
    else
      "#{KD.apiUri + '/images/default.app.thumb.png'}"

    @thumb = new KDCustomHTMLView
      tagName     : "img"
      bind        : "error"
      error       : =>
        @thumb.$().attr "src", "/images/default.app.thumb.png"
      attributes  :
        src       : thumb

  viewAppended:->
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
    <div class="profileleft">
      <span>
        <a class='profile-avatar' href='#'>{{> @thumb}}</a>
      </span>
    </div>
    <section class="right-overflow">
      <h3 class='profilename'>{{#(title)}}<cite>by {{#(manifest.author)}}</cite></h3>
      <div class="installerbar clearfix">
        {{> @installButton}}
        {{> @openButton}}
        {{> @updateButton}}
        <div class="versionstats updateddate">Version {{ #(manifest.version) || "---" }}<p>Updated: ---</p></div>
        <div class="versionscorecard">
          <div class="versionstats">{{#(counts.installed) || 0}}<p>INSTALLS</p></div>
          <div class="versionstats">{{#(meta.likes) || 0}}<p>Likes</p></div>
          <div class="versionstats">{{#(counts.followers) || 0}}<p>Followers</p></div>
        </div>
        <div class="appfollowlike">
          {{> @followButton}}
          {{> @likeButton}}
        </div>
        <div class="appfollowlike">
          {{> @approveButton}}
          {{> @removeButton}}
        </div>
      </div>
    </section>
    """
