class TeamworkDashboard extends JView

  constructor: (options = {}, data) ->

    options.cssClass = "tw-dashboard active"

    super options, data

    @fetchManifests()

    @playgrounds  = new KDCustomHTMLView
      cssClass    : "tw-playgrounds"

  createPlaygrounds: (manifests) ->
    manifests?.forEach (manifest) =>
      @setClass "ready"
      @playgrounds.addSubView view = new KDCustomHTMLView
        cssClass  : "tw-playground-item"
        partial   : """
          <img src="#{manifest.icon}" />
          <div class="content">
            <h4>#{manifest.name}</h4>
            <p>#{manifest.description}</p>
          </div>
        """
      view.addSubView new KDButtonView
        cssClass  : "tw-play-button"
        title     : "Play"
        callback  : =>
          new KDNotificationView
            title : "Coming Soon"
          # @getDelegate().handlePlaygroundSelection manifest.name, manifest.manifestUrl

  fetchManifests: ->
    filename = if location.hostname is "localhost" then "manifest-dev" else "manifest"
    delegate = @getDelegate()

    delegate.fetchManifestFile "#{filename}.json", (err, manifests) =>
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
      <div class="tw-playgrounds-container">
        <p class="loading">Loading Playgrounds...</p>
        {{> @playgrounds}}
      </div>
    """
