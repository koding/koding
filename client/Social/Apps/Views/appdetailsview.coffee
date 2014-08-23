class AppDetailsView extends KDScrollView

  JView.mixin @prototype

  constructor:->

    super

    @app = app = @getData()

    {identifier, version, authorNick} = app.manifest

    @appLogo = new KDView
      cssClass : 'app-logo'
      partial  : """
        <span class='logo'>#{app.name[0]}</span>
      """

    @statusWidget = new KDView
      cssClass : KD.utils.curry 'status-widget', app.status
      tooltip  : title : {
        'github-verified': "Public"
        'not-verified'   : "Private"
        'verified'       : "Verified"
      }[app.status]

    @appLogo.addSubView @statusWidget

    @appLogo.setCss 'backgroundColor', KD.utils.getColorFromString app.name

    @actionButtons = new KDView cssClass: 'action-buttons'

    @removeButton = new KDButtonView
      title    : "Delete"
      style    : "delete"
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
              callback   : -> modal.destroy()

    if KD.checkFlag('super-admin') or app.originId is KD.whoami().getId()
      @actionButtons.addSubView @removeButton

    @approveButton = new KDToggleButton
      style           : "approve"
      dataPath        : "approved"
      defaultState    : if app.status is 'verified' then "Disapprove" else "Approve"
      states          : [
        title         : "Approve"
        callback      : (callback)=>
          @approveApp app, yes, callback
      ,
        title         : "Disapprove"
        callback      : (callback)=>
          @approveApp app, no, callback

      ]
    , app

    if KD.checkFlag('super-admin')
      @actionButtons.addSubView @approveButton

    @actionButtons.addSubView @runButton = new KDButtonView
      title      : "Run"
      style      : "run"
      callback   : ->
        KodingAppsController.runExternalApp app

    {icns, identifier, version, authorNick} = app.manifest

    @updatedTimeAgo = new KDTimeAgoView {}, @getData().createdAt

    @slideShow = new KDCustomHTMLView
      tagName   : "ul"
      partial   : do ->
        slides = app.manifest.screenshots or []
        tmpl = ''
        for slide in slides
          tmpl += "<li><img src=\"#{KD.appsUri}/#{authorNick}/#{identifier}/#{version}/#{slide}\" /></li>"
        return tmpl

    @detailsView = new KDView
      cssClass  : "app-extras"

    if app.status in ['verified', 'github-verified']

      {repository} = app.manifest
      repoUrl   = repository.replace /^git\:\/\//, 'https://'
      proxyUrl  = repository.replace /^git\:\/\/github.com/, KD.config.appsUri
      baseUrl   = "#{proxyUrl}/#{app.manifest.commitId or 'master'}"
      readmeUrl = "#{baseUrl}/README.md"

      @githubMenu = new KDButtonViewWithMenu
        itemChildClass : LinkMenuItemView
        cssClass       : "github-menu"
        style          : "resurrection"
        menu           :
          Repository   : link : repoUrl
          Issues       : link : "#{repoUrl}/issues"
          Commits      : link : "#{repoUrl}/commits/#{app.manifest.commitId or 'master'}"
          Wiki         : link : "#{repoUrl}/wiki"

      # TODO: Implement clone app ~ GG
      # @detailsView.addSubView new KDButtonView
      #   title    : "Clone to my VM"
      #   cssClass : "solid mini"
      #   callback : -> alert()

      @detailsView.addSubView readmeView = new KDView
        cssClass : 'readme'
        partial  : "<p>Fetching readme...</p>"

      $.ajax
        url      : readmeUrl
        timeout  : 5000
        success  : (content, status)->
          if status is "success"
            readmeView.setClass 'has-markdown'
            readmeView.updatePartial KD.utils.applyMarkdown content
        error    : ->
          warn arguments
          readmeView.updatePartial "<p>README.md not found on #{repository}</p>"

    else

      @githubMenu = new KDView


  approveApp:(app, state, callback)->

    if state
      text  = 'approve'
      style = 'modal-clean-green'
    else
      text  = 'disapprove'
      style = 'modal-clean-red'

    modal = KDModalView.confirm
      title       : 'Are you sure?'
      description : "Are you sure you want to #{text} this application?"
      ok          :
        style     : style
        title     : text.capitalize()
        callback  : ->
          app.approve state, (err)->
            if err then warn err
            modal.destroy()
            callback? err


  pistachio:->

    {name, manifest} = @getData()
    desc = manifest?.description or ""
    name = manifest?.title or name
    """

      {{> @appLogo}}

      <div class="app-info">
        <h3><a href="/#{@getData().slug}">#{name}</a></h3>
        <h4>{{#(manifest.author)}}</h4>

        <div class="appdetails">
          <article>#{desc}</article>
        </div>

      </div>
      <div class="installerbar">

        <div class="versionstats updateddate">
          Version {{ #(manifest.version) || "---" }}
          <p>Released {{> @updatedTimeAgo}}</p>
          {{> @githubMenu}}
        </div>

        {{> @actionButtons}}

      </div>

      {{> @detailsView}}

    """
