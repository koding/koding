class GitHub

  GITHUB_API_URL = "https://api.github.com"
  @_repoCache = {}

  @fetch = (url, params, callback)->

    unless callback
      [params, callback] = [callback, params]
    callback ?= noop

    req =
      url      : "#{GITHUB_API_URL}#{url}"
      dataType : "jsonp"
      success  : callback
    req.data   = params  if params

    $.ajax req
    null

  @fetchUserRepos = (username, callback = noop, force)->

    if force then @resetCache username
    if @_repoCache[username]?.length > 0
      callback null, @_repoCache[username]
      return

    repos = []
    page  = 0

    do fetch = =>

      page++

      @fetch "/users/#{username}/repos", {
        sort     : 'updated'
        per_page : 30
        page
      }, (response, state, req) =>

        {meta, data} = response
        {status} = meta

        unless state is 'success' and status is 200
          return callback {
            message: "Failed to fetch repos for #{username}"
            status, state
          }, repos

        repos = repos.concat data

        link = meta?.Link?[0]
        if link?[1]?.rel is "next" then fetch()
        else
          @_repoCache[username] = repos
          callback null, repos

  @fetchMyRepos = (callback = noop, force = no)->

    me = KD.whoami()
    me.fetchOAuthInfo (err, oauth)=>

      return callback err  if err?
      return callback {
        message : "There is no linked GitHub account with this account."
      }  unless oauth?.github?

      {username} = oauth.github
      @fetchUserRepos username, callback, force

  @resetCache = (username)->

    if username
    then delete @_repoCache[username]
    else delete @_repoCache

    null

  @link = (callback = noop)->

    me = KD.whoami()
    me.fetchOAuthInfo (err, oauth)->
      return callback err  if err?

      if oauth?.github?
        return callback
          message : "Already linked with #{oauth.github.username}"

      {mainController, oauthController} = KD.singletons
      oauthController.openPopup 'github'

      handler = -> callback null

      mainController.off  "ForeignAuthSuccess.github", handler
      mainController.once "ForeignAuthSuccess.github", handler

  @rateLimit = (callback = noop)->

    @fetch "/rate_limit", (response, state, req)->

      {meta, data} = response
      {status} = meta

      if data.rate?
        return callback null, data.rate

      callback {message: "Failed to fetch rate_limit", state, status}

  @username = (callback)->

    me = KD.whoami()
    me.fetchOAuthInfo (err, oauth)->
      if err? then callback ''
      else callback if oauth?.github? then oauth.github.username else ''

  @makeLink = (path, text)->
    """
      <a href='https://github.com/#{path}' target='_github_#{path}'>
        #{if text then text else "github.com/"+path}
      </a>
    """
