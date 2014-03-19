class AppDetailsView extends KDScrollView

  constructor:->

    super

    @app = app = @getData()

    {identifier, version, authorNick} = app.manifest

    @appLogo = new KDView
      cssClass : 'app-logo'
      partial  : """
        <span class='logo'>#{app.name[0]}</span>
      """

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

    if KD.checkFlag('super-admin')
      @actionButtons.addSubView @approveButton

    @actionButtons.addSubView @runButton = new KDButtonView
      title      : "Run"
      style      : "run"
      callback   : ->
        KodingAppsController.runExternalApp app

    {icns, identifier, version, authorNick} = app.manifest

    @updatedTimeAgo = new KDTimeAgoView {}, @getData().meta.createdAt

    @slideShow = new KDCustomHTMLView
      tagName   : "ul"
      pistachio : do ->
        slides = app.manifest.screenshots or []
        tmpl = ''
        for slide in slides
          tmpl += "<li><img src=\"#{KD.appsUri}/#{authorNick}/#{identifier}/#{version}/#{slide}\" /></li>"
        return tmpl

    # @reviewView = new ReviewView {}, app

  viewAppended: JView::viewAppended

  pistachio:->

    if @app.manifest.screenshots?.length
      screenshots = """
        <header><a href='#'>Screenshots</a></header>
        <section class='screenshots'>{{> @slideShow}}</section>
      """
    desc = @getData().manifest?.description or ""

    """

      {{> @appLogo}}

      <div class="app-info">
        <h3><a href="/#{@getData().slug}">#{@getData().name}</a></h3>
        <h4>{{#(manifest.author)}}</h4>

        <div class="appdetails">
          <article>#{desc}</article>
        </div>

      </div>
      <div class="installerbar">

        <div class="versionstats updateddate">
          Version {{ #(manifest.version) || "---" }}
          <p>Released {{> @updatedTimeAgo}}</p>
        </div>

        {{> @actionButtons}}

      </div>
    """
    #   <header>
    #     <a href='#'>About {{#(title)}}</a>
    #   </header>
    #   <section>
    #     {{ @utils.applyTextExpansions #(manifest.description)}}
    #   </section>

    #   #{screenshots or ""}

    #   <header>
    #     <a href='#'>Reviews</a>
    #   </header>
    #   <section>
    #     {{> @reviewView}}
    #   </section>

    # """
