class GitHub.Modal extends KDModalView

  constructor:(options = {}, data)->

    options = $.extend
      title    : "GitHub repositories"
      cssClass : "github-modal"
      width    : 540
      overlay  : yes
    , options

    super options, data

  viewAppended:->

    @addSubView @loader = new KDLoaderView
      cssClass    : "loader"
      showLoader  : yes
      size        :
        width     : 16

    @addSubView @refreshButton = new KDButtonView
      style     : 'refresh-button hidden'
      title     : ''
      icon      : yes
      iconOnly  : yes
      iconClass : 'cog'
      callback  : @lazyBound 'checkLinkStatus', yes

    @addSubView @message = new KDView
      cssClass : 'message'

    @addSubView @container = new KDView
      cssClass : 'hidden'

    @repoController     = new KDListViewController
      viewOptions       :
        type            : 'github'
        wrapper         : yes
        itemClass       : GitHub.RepoItem
        itemOptions     :
          buttonTitle   : 'publish'
      noItemFoundWidget : new KDView
        cssClass        : 'noitem-warning'
        partial         : "There is no repository to show."

    @container.addSubView \
      @repoListView = @repoController.getView()

    @forwardEvent @repoController.getListView(), 'RepoSelected'

    @checkLinkStatus()

  showRepos:(username, force)->

    @message.updatePartial "Fetching repositories from #{GitHub.makeLink username}..."

    GitHub.fetchUserRepos username, (err, repos)=>

      if err
        @loader.hide()
        @refreshButton.show()
        @message.updatePartial """
          An error occured while fetching
          repos from #{GitHub.makeLink username}...
        """
        new KDNotificationView title: err.message  if err.message?

        KD.utils.defer =>
          @_windowDidResize()

        return warn err

      if @repoFilter?
        repos = @repoFilter repos

      @repoController.replaceAllItems repos

      KD.utils.defer =>
        @_windowDidResize()
        @message.updatePartial "Repositories of #{GitHub.makeLink username}"
        @refreshButton.show()
        @loader.hide()

    , force

  checkLinkStatus:(force)->

    @message.updatePartial "Checking GitHub account status..."
    @refreshButton.hide()
    @loader.show()

    me = KD.whoami()
    me.fetchOAuthInfo (err, oauth)=>

      return callback err  if err?

      @container.show()

      unless oauth?.github?

        @loader.hide()
        @message.updatePartial """
          To fetch GitHub repositories you need to link your Koding account
          with your GitHub account. Click <span>here</span> to link now.
        """

        @container.hide()
        @message.on 'click', =>
          @loader.show()
          @message.updatePartial "Waiting for authentication..."
          GitHub.link (err)=>
            @checkLinkStatus()  unless err

      else

        @message.off 'click'
        @container.show()
        @showRepos oauth.github.username, force
