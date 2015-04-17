{
  error_404
  serve
  serveHome
  isLoggedIn
  isInAppRoute
}                      = require './../helpers'
koding                 = require './../bongo'
{ generateFakeClient } = require "./../client"
Crawler                = require './../../crawler'

module.exports = (req, res, next)->

  {JName, JGroup}       = koding.models
  {params}              = req
  {name, section, slug} = params

  path = name
  path = "#{path}/#{section}"  if section
  path = "#{path}/#{slug}"     if slug

  # When we try to access /Activity/Message/New route, it is trying to
  # fetch message history with channel id = 'New' and returning:
  # Bad Request: strconv.ParseInt: parsing "New": invalid syntax error.
  # Did not like the way I resolve this, but this handler function is already
  # saying 'Refactor me' :)
  return next()  if section is 'Message' and slug is 'New'

  return res.redirect 301, req.url.substring 7  if name in ['koding', 'guests']
  # Checks if its an internal request like /Activity, /Terminal ...
  #
  bongoModels = koding.models

  if isInAppRoute name
    if name is 'Develop'
      return res.redirect 301, '/IDE'

    if name is 'Activity'
      isLoggedIn req, res, (err, loggedIn, account)->

        return  serveHome req, res, next  if loggedIn

        staticHome = require "../crawler/staticpages/kodinghome"
        return res.status(200).send staticHome() if path is ""

        return Crawler.crawl koding, {req, res, slug: path}

    else

      generateFakeClient req, res, (err, client)->

        isLoggedIn req, res, (err, loggedIn, account)->
          prefix   = if loggedIn then 'loggedIn' else 'loggedOut'

          serveSub = (err, subPage)->
            return next()  if err
            serve subPage, res

          path = if section then "#{name}/#{section}" else name

          JName.fetchModels path, (err, result) ->

            if err
              options = { account, name, section, client,
                          bongoModels, params }

              JGroup.render[prefix].subPage options, serveSub
            else if not result? then next()
            else
              { models } = result
              options = { account, name, section, models,
                          client, bongoModels, params }

              JGroup.render[prefix].subPage options, serveSub

  # Checks if its a User or Group from JName collection
  #
  else
    isLoggedIn req, res, (err, loggedIn, account)->
      return res.status(404).send error_404()  if err

      JName.fetchModels name, (err, result)->
        return next err  if err
        return res.status(404).send error_404()  unless result?
        { models } = result
        if models.last?
          if models.last.bongo_?.constructorName isnt "JGroup" and not loggedIn
            return Crawler.crawl koding, {req, res, slug: name, isProfile: yes}

          generateFakeClient req, res, (err, client)->
            homePageOptions = { section, account, bongoModels,
                                client, params, loggedIn }

            models.last.fetchHomepageView homePageOptions, (err, view)->
              if err then next err
              else if view? then res.send view
              else res.status(404).send error_404()
        else next()