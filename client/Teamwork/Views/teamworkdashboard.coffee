class TeamworkDashboard extends JView

  constructor: (options = {}, data) ->

    options.cssClass = "tw-dashboard"

    super options, data

    @fetchManifests()

    @playgrounds  = new KDCustomHTMLView
      cssClass    : "tw-playgrounds"

  createPlaygrounds: (manifests) ->
    @playgrounds.addSubView new KDCustomHTMLView
      cssClass    : "tw-playground-item default-item import" # plus: add-new
      partial     : "<div></div><p>Import Project</p>"
      click       : =>
        KD.mixpanel "Teamwork import modal, click"
        @getDelegate().teamwork.showImportModal()

    manifests?.forEach (manifest) =>
      return if manifest.name is "Facebook"
      @playgrounds.addSubView view = new KDCustomHTMLView
        cssClass  : "tw-playground-item"
        partial   : "<img src='#{manifest.icon}'/> <p>#{manifest.name}</p>"
        click     : =>
          @getDelegate().handlePlaygroundSelection manifest.name, manifest.manifestUrl

    @setClass "ready"

  fetchManifests: ->
    delegate = @getDelegate()
    delegate.fetchManifestFile "manifest.json", (err, manifests) =>
      if err
        @setClass "ready"
        @playgrounds.hide()
        return new KDNotificationView
          type     : "mini"
          cssClass : "error"
          title    : "Could not fetch Playground manifest."
          duration : 4000

      delegate.playgroundsManifest = manifests
      @createPlaygrounds manifests

  pistachio: ->
    """
      <div class="headline">
        <h1>Welcome to Teamwork</h1>
        <p>Teamwork is a collaborative IDE for Koding. You can share your code, invite friends and code together.</p>
        <div class="separator"></div>
        <p>Start a new project from scratch, import a git repository or a zip from GitHub. You can also play with one of the ready to go templates below:</p>
      </div>
      <div class="tw-playgrounds-container">
        <p class="loading">Loading Playgrounds...</p>
        {{> @playgrounds}}
      </div>
    """
