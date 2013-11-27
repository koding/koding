class TeamworkDashboard extends JView

  constructor: (options = {}, data) ->

    options.cssClass = "tw-dashboard"

    super options, data

    @teamUpButton = new KDButtonView
      title       : "Team Up!"
      cssClass    : "tw-teamup-button"
      callback    : ->

    @joinInput    = new KDHitEnterInputView
      cssClass    : "tw-dashboard-input"
      placeholder : "Session key or join url"
      validate    :
        rules     : required: yes
        messages  : required: "Enter session key or URL to join."
      callback    : => @handleJoinSession()

    @joinButton   = new KDButtonView
      iconOnly    : yes
      iconClass   : "join-in"
      cssClass    : "tw-dashboard-button"
      callback    : => @handleJoinSession()

    @importInput  = new KDInputView
      cssClass    : "tw-dashboard-input"
      placeholder : "Url to import your VM"
      callback    : ->

    @importButton = new KDButtonView
      iconOnly    : yes
      iconClass   : "import"
      cssClass    : "tw-dashboard-button"
      callback    : ->

    @playgrounds  = new KDCustomHTMLView
      cssClass    : "tw-playgrounds"

    @sessionButton = new KDButtonView
      cssClass    : "tw-session-button"
      title       : "Start your session now!"

    manifests     = @getDelegate().playgroundsManifest

  createPlaygrounds: (manifests) ->
    manifests.forEach (manifest) =>
      @setClass "ready"
      @playgrounds.addSubView view = new KDCustomHTMLView
        cssClass  : "tw-playground-item"
        partial   : """
          <img src="#{manifest.icon}" />
          <div class="content">
            <h4>#{manifest.name}</h4>
            <p>#{manifest.description}</p>
          </div>
          <div class="btn">Play</div>
        """

  pistachio: ->
    """
      <div class="welcome">
        <h2 class="title">Welcome to Teamwork</h2>
        <div class="video">
          <iframe width="500" height="280" src="//www.youtube.com/embed/zrPxONt1uyo?rel=0" frameborder="0" allowfullscreen></iframe>
        </div>
        <div class="what-is-tw">
          <h2>What is Teamwork?</h2>
          <p>Teamwork is an environment that lets you share your VM and collaborate in realtime with other users.</p>
          <ul>
            <li>Team up with your friends on your session.</li>
            <li>Share your session as a ZIP file.</li>
            <li>Join another session.</li>
            <li>Clone GitHub repositories and start working on it with your friends.</li>
          </ul>
        </div>
      </div>
      {{> @sessionButton}}
      <div class="actions">
        <div class="tw-items-container">
          <div class="item team-up">
            <div class="badge"></div>
            <h3>Team Up</h3>
            <p>Team up and start working with your friends. Invite your Koding friends or invite them via email.</p>
            {{> @teamUpButton}}
          </div>
          <div class="item join-in">
            <div class="badge"></div>
            <h3>Join In</h3>
            <p>Join your friend's Teamwork session. You can enter a Teamwork Session Key or a full Koding URL.</p>
            <div class="tw-input-container">
              {{> @joinInput}}
              {{> @joinButton}}
            </div>
          </div>
          <div class="item import">
            <div class="badge"></div>
            <h3>Import</h3>
            <p>Import content to your VM and start working on it. It might be a zip file or a GitHub repository.</p>
            <div class="tw-input-container">
              {{> @importInput}}
              {{> @importButton}}
            </div>
          </div>
        </div>
      </div>
      <div class="tw-playgrounds-container">
        <p class="loading">Loading Playgrounds...</p>
        {{> @playgrounds}}
      </div>
    """
