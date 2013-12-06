class AppView extends KDView

  constructor:(options, data)->

    super

    app = @getData()

    appManager = KD.getSingleton "appManager"

    if KD.checkFlag('super-admin') or app.originId is KD.whoami().getId()
      @removeButton = new KDButtonView
        title    : "Delete"
        style    : "kdwhitebtn"
        callback : =>
          modal = new KDModalView
            title          : "Delete #{Encoder.XSSEncode app.manifest.name}"
            content        :
              """
                <div class='modalformline'>Are you sure you want to delete
                <strong>#{Encoder.XSSEncode app.manifest.name}</strong>
                application?</div>
              """
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
                      @destroy()
                    else
                      new KDNotificationView
                        type     : "mini"
                        cssClass : "error editor"
                        title    : "Error, please try again later!"
                      warn err
              cancel       :
                style      : "modal-cancel"
                callback   : -> modal.destroy

    else

      @removeButton  = new KDView

    if KD.checkFlag('super-admin')

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

    else

      @approveButton = new KDView

    @runButton   = new KDButtonView
      title      : "Run"
      style      : "cupid-green"
      callback   : ->
        KodingAppsController.runExternalApp app

    {icns, identifier, version, authorNick} = app.manifest
    thumb = if icns and (icns['256'] or icns['512'] or icns['128'] or icns['160'] or icns['64'])
      "#{KD.appsUri}/#{authorNick}/#{identifier}/#{version}/#{if icns then icns['256'] or icns['512'] or icns['128'] or icns['160'] or icns['64']}"
    else
      "#{KD.apiUri + '/images/default.app.thumb.png'}"

    @thumb = new KDCustomHTMLView
      tagName     : "img"
      bind        : "error"
      error       : =>
        @thumb.setAttribute "src", "/images/default.app.thumb.png"
      attributes  :
        src       : thumb

    @updatedTimeAgo = new KDTimeAgoView {}, @getData().meta.createdAt

  viewAppended:->
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    timeAgoText = if @getData().versions?.length > 1 then "Updated" else "Released"
    """
    <div class="profileleft">
      <span>
        <a class='profile-avatar' href='#'>{{> @thumb}}</a>
      </span>
    </div>
    <section class="right-overflow">
      <h3 class='profilename'>{{#(title)}}<cite>by {{#(manifest.author)}}</cite></h3>
      <div class="installerbar clearfix">
        {{> @runButton}}
        <div class="versionstats updateddate">Version {{ #(manifest.version) || "---" }}<p>#{timeAgoText} {{> @updatedTimeAgo}}</p></div>
        <div class="versionscorecard">
          <div class="versionstats">{{#(counts.installed) || 0}}<p>INSTALLS</p></div>
          <div class="versionstats">{{#(meta.likes) || 0}}<p>Likes</p></div>
          <div class="versionstats">{{#(counts.followers) || 0}}<p>Followers</p></div>
        </div>
        <div class="appfollowlike">
          {{> @approveButton}}
          {{> @removeButton}}
        </div>
      </div>
    </section>
    """
