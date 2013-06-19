class AppView extends KDView

  constructor:(options, data)->

    super

    app = @getData()
    @appManager = KD.getSingleton "appManager"

    @followButton = new KDToggleButton
      style           : "kdwhitebtn"
      dataPath        : "followee"
      defaultState    : "Follow"
      disabled        : !app.approved
      states          : [
        title         : "Follow"
        callback      : (cb)->
          KD.requireMembership
            callback  : =>
              app.follow (err)->
                cb? err
                KD.track "Apps", "Follow", app.title unless err

            onFailMsg : "Login required to follow Apps"
            tryAgain  : yes
      ,
        title         : "Unfollow"
        callback      : (callback)->
          app.unfollow (err)->
            callback? err
            KD.track "Apps", "Unfollow", app.title unless err
      ]
    , app

    @likeButton = new KDToggleButton
      style           : "kdwhitebtn"
      defaultState    : 'Like'
      disabled        : !app.approved
      states          : [
        title         : "Like"
        callback      : (cb)->
          KD.requireMembership
            callback  : =>
              app.like (err)->
                cb? err
                KD.track "Apps", "Like", app.title unless err
            onFailMsg : "Login required to like Apps"
            tryAgain  : yes
      ,
        title         : "Unlike"
        callback      : (callback)->
          app.like (err)->
            callback? err
            KD.track "Apps", "Unlike", app.title unless err
      ]
    , app

    if KD.isLoggedIn()
      KD.whoami().isFollowing? app.getId(), "JApp", (err, following) =>
        app.followee = following
        @followButton.setState "Unfollow"  if following

    appsController = KD.getSingleton("kodingAppsController")

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
                      @appManager.open "Apps", yes, (instance)=>
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
            appsController.installApp app, version, (err)=>
              KD.track "Apps", "Install", app.title unless err
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
          appsController.installApp app, app.versions.last, (err)=>
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
          appsController.installApp app, app.versions.last, (err)=>
            @hideLoader()

    @runButton = new KDButtonView
      title     : "Run"
      style     : "clean-gray"
      callback  : =>
        KD.track "Apps", "OpenApplication", app.title
        @appManager.open app.title

    @runButton.hide()

    @updateButton = new KDButtonView
      title       : "Update"
      style       : "cupid-green"
      callback    : =>
        delete appsController.notification
        appsController.updateUserApp app.manifest, =>
          KD.getSingleton("router").handleRoute "Develop"

    @updateButton.hide()

    appsController.fetchApps (err, manifests) =>
      # user have the app, show just show open button
      if app.title in Object.keys manifests
        @installButton.hide()
        @runButton.show()

      appName = app.manifest.name
      version = manifests?[appName]?.version # strange, but it's not working with { ... }

      if version and appsController.isAppUpdateAvailable appName, version
        @updateButton.show()

    {icns, identifier, version, authorNick} = app.manifest
    thumb = if icns and (icns['256'] or icns['512'] or icns['128'] or icns['160'] or icns['64'])
      "#{KD.appsUri}/#{authorNick}/#{identifier}/#{version}/#{if icns then icns['256'] or icns['512'] or icns['128'] or icns['160'] or icns['64']}"
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
        {{> @runButton}}
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
