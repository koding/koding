{ isLoggedIn, error_404, error_500 } = require '../server/helpers'

kodinghome = require './staticpages/kodinghome'
grouphome = require './staticpages/grouphome'
subPage = require './staticpages/subpage'
profile = require './staticpages/profile'

module.exports =
  crawl: (bongo, req, res, slug)->
    {JName} = bongo.models
    [name, section] = slug.split("/")
    return res.redirect 302, req.url.substring 7  if name in ['koding', 'guests']
    [firstLetter] = name

    if firstLetter.toUpperCase() is firstLetter
      if section
        isLoggedIn req, res, (err, loggedIn, account)->
          if name is "Develop"
            content = subPage {account, name, section}
            return res.send 200, content

          JName.fetchModels "#{name}/#{section}", (err, models)->
            console.error err if err
            content = subPage {account, name, section, models}
            return res.send 200, content
      else return console.log "no section is given"
    else
      isLoggedIn req, res, (err, loggedIn, account)->
        JName.fetchModels name, (err, models, jname)->
          return res.send 500, error_500()  if err
          return res.send 404, error_404()  if not models
          # this is a group
          if jname.slugs.first.usedAsPath is "slug"
            group = models.last
            content = grouphome {group}
            return res.send 200, content

            # this is a user
          else
            models.last.fetchOwnAccount (err, account)->
              content = profile {account}
              return res.send 200, content

