{ isLoggedIn, error_404, error_500 } = require '../server/helpers'

kodinghome = require './staticpages/kodinghome'
grouphome = require './staticpages/grouphome'
activity = require './staticpages/activity'
profile = require './staticpages/profile'

forceTwoDigits = (val) ->
  if val < 10
    return "0#{val}"
  return val

formatDate = (date) ->
  year = date.getFullYear()
  month = date.getMonth()
  day = forceTwoDigits(date.getDate())
  hour = forceTwoDigits(date.getHours())
  minute = forceTwoDigits(date.getMinutes())

  # What about i18n? Does GoogleBot crawl in different languages?
  months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", 
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
  monthName = months[month]
  return "#{day} #{monthName} #{year} #{hour}:#{minute}"

module.exports =
  crawl: (bongo, req, res, slug)->
    {Base, race, dash, daisy} = require "bongo"
    {JName, JAccount} = bongo.models
    {Relationship} = require 'jraphical'

    # Are all slugs start with a '/'? 
    [slash, name, section] = slug.split("/")
    return res.redirect 302, req.url.substring 7 if name in ['koding', 'guests']
    [firstLetter] = name

    if firstLetter.toUpperCase() is firstLetter
      if section
        isLoggedIn req, res, (err, loggedIn, account)->
          if name is "Develop"
            content = subPage {account, name, section}
            return res.send 200, content

          JName.fetchModels "#{name}/#{section}", (err, models)=>
            console.error err if err
            model = models.first if models and Array.isArray 
            model?.fetchRelativeComments limit:10, after:"", (err, comments)=>
              # Get comments authors, put comment info into commentSummaries
              queue = [0..comments.length].map (index)=>=>
                comment = comments[index]
                if comment?.data
                  createdAt = formatDate(new Date(comment.timestamp_))
                  commentSummary = {body: comment.data.body, createdAt: createdAt}
                  selector = 
                  {
                    "targetId" : comment.getId(),
                    "sourceName": "JAccount"
                  }
                  Relationship.one selector, (err, rel) =>
                    if err
                      console.error err 
                      return queue.next()
                    sel = { "_id" : rel.data.sourceId}
                    JAccount.one sel, (err, acc) =>
                      if err
                        console.error err 
                        return queue.next()
                      commentSummary.name = acc.data.profile.firstName + " " 
                      commentSummary.name += acc.data.profile.lastName
                      queue.commentSummaries or= []
                      if commentSummary.body
                        queue.commentSummaries.push commentSummary
                      queue.next()
                else queue.next()
              queue.push => 
                statusUpdateId = model.getId()
                jAccountId = model.data.originId
                selector = 
                {
                  "sourceId" : statusUpdateId,
                  "as" : "author"
                }
                Relationship.one selector, (err, rel) =>
                  if err
                      console.error err 
                      return queue.next()
                  sel = 
                  {
                    "_id" : rel.data.targetId
                  }
                  JAccount.one sel, (err, acc) =>
                    if err
                      console.error err 
                      return queue.next()
                    fullName = acc.data.profile.firstName + " " 
                    fullName += acc.data.profile.lastName
                    activityContent = {
                      fullName : fullName,
                      hash : acc.data.profile.hash,
                      name : if model?.title then model.title else section,
                      body : if model?.body  then model.body  else "",
                      createdAt : formatDate(model?.data?.meta?.createdAt),
                      numberOfComments : comments.length,
                      numberOfLikes : model?.data?.meta?.likes,
                      comments : queue.commentSummaries,
                      tags : model?.data?.meta?.tags,
                      type : model?.bongo_?.constructorName
                    }
                    content = activity {activityContent, name, section, models}
                    return res.send 200, content
              daisy queue
      else return console.log "no section is given"
    else
      isLoggedIn req, res, (err, loggedIn, account)->
        JName.fetchModels name, (err, models, jname)->
          return res.send 500, error_500()  if err
          return res.send 404, error_404()  if not models
          # this is a group, we are not serving groups to bots anymore.
          if jname.slugs.first.usedAsPath is "slug"
            return res.send 404, error_404()

          # this is a user
          else
            models.last.fetchOwnAccount (err, account)->
              content = profile {account}
              return res.send 200, content

