kd             = require 'kd'
whoami         = require 'app/util/whoami'
GitHub         = require 'app/extras/github/github'
RepoItem       = require 'app/extras/github/views/repoitem'

module.exports = class GithubFlow extends kd.View

  constructor: (options = {}, data) ->

    options.cssClass = 'github'
    super options, data


  viewAppended: ->

    @addSubView @loader = new kd.LoaderView
      cssClass    : "loader"
      showLoader  : yes
      size        :
        width     : 16

    @addSubView @refreshButton = new kd.ButtonView
      style     : 'refresh-button hidden'
      title     : 'Refresh'
      callback  : @lazyBound 'showRepos', 'koding', yes

    @repoController     = new kd.ListViewController
      viewOptions       :
        type            : 'github'
        wrapper         : yes
        itemClass       : RepoItem
        itemOptions     :
          buttonTitle   : 'publish'
      noItemFoundWidget : new kd.View
        cssClass        : 'noitem-warning'
        partial         : "There is no repository to show."

    @addSubView @repoListView = @repoController.getView()
    @repoListView.hide()

    @showRepos 'koding'


  showRepos: (username, force) ->

    @loader.show()
    @refreshButton.hide()
    @repoListView.hide()

    GitHub.fetchUserRepos username, (err, repos) =>

      @refreshButton.show()
      @loader.hide()

      if err
        new kd.NotificationView title: err.message  if err.message?
        return kd.warn err

      @repoController.replaceAllItems repos
      @repoListView.show()

    , force
