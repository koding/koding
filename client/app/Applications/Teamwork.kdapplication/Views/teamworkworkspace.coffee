class TeamworkWorkspace extends CollaborativeWorkspace

  createLoader: ->
    @container.addSubView @loader = new KDCustomHTMLView
      cssClass   : "teamwork-loader"
      tagName    : "img"
      attributes :
        src      : "#{KD.apiUri}/images/teamwork/loading.gif"
