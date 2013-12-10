jraphical = require 'jraphical'
module.exports = class JBadge extends jraphical.Module
  {permit}          = require './group/permissionset'
  {daisy, secure}   = require 'bongo'

  @trait __dirname, '../traits/filterable'

  @share()
  @set
    permissions           :
      'create badge'      : []
      'delete badge'      : []
      'edit badge'        : []
      'assign badge'      : ['moderator']
      'list badges'       : ['member','moderator']
      'remove user badge' : ['moderator']
    schema                :
      title               : String
      description         : String
      rule                : String
      invisible           :
        type              : Boolean
        default           : false
      iconURL             :
        type              : String
      reward              : String
      createdAt           :
        type              : Date
        default           : -> new Date
    sharedMethods         :
      static              : ["listBadges", "getUserBadges", "create","fetchBadgeUsers",
      "fetchUsersByRule", "checkEligibleBadges"]
      instance            : ["modify", "deleteBadge", "assignBadge",
      "removeBadgeFromUser", "assignBadgeBatch"]

  @create: permit 'create badge',
    success:(client, badgeData, callback=->)->
      badge = new JBadge badgeData
      badge.save (err)=>
        callback err, badge

  @listBadges: permit 'list badges',
    success: (client, selector, callback=->)->
      JBadge.some selector,{limit:50},callback

  modify: permit 'edit badge',
    success: (client, formData, callback)->
      @update $set : formData, callback

  deleteBadge : permit 'delete badge',
    success: (client, callback=->)->
      @remove (err) =>
        callback err, null

  assignBadge : permit 'assign badge',
    success: (client, user, callback)->
      JAccount = require './account'
      JAccount.one '_id' : user.getId(), (err, account)=>
        account.addBadge this, callback

  assignBadgeBatch : permit 'assign badge',
    success: (client, accountIds, callback)->
      JAccount = require './account'
      errors = []
      if accountIds isnt ""
        queue  = accountIds.split(",").map (id) =>=>
          JAccount.one "_id" : id, (err, account)=>
            return err if err
            jraphical.Relationship.one
              as            : "badge"
              targetId      : @getId()
              sourceId      : account.getId()
            , (err, rel)=>
              if not rel
                account.addBadge this, (err, badge)->
                  errors.push err if err
            queue.next()

        queue.push -> callback if errors.length > 0 then errors else null
        daisy queue

  removeBadgeFromUser : permit 'remove user badge',
    success: (client, user, callback)->
      JAccount       = require './account'
      {Relationship} = jraphical

      JAccount.one {'profile.nickname' : user.profile.nickname}, (err, account)=>
        Relationship.remove {
          targetId   : @getId()
          targetName : 'JBadge'
          sourceId   : account.getId()
          sourceName : 'JAccount'
          as         : "badge"
        }, callback

  @getUserBadges:(user, callback) ->
    JAccount = require './account'
    JAccount.one 'profile.nickname' : user.profile.nickname, (err, account)=>
      account.fetchBadges callback

  @findAccounts : (cursor, items, callback)->
    cursor.nextObject (err, rel) =>
      if err
        callback items
      else if rel
        items.push rel.sourceId
        @findAccounts cursor, items, callback
      else
        callback items

  @fetchBadgeUsers:permit 'list badges',
    success: (client, badgeId, callback)->
      query =
          targetName : "JBadge"
          targetId   : badgeId
          as         : "badge"
          sourceName : "JAccount"
      jraphical.Relationship.cursor query, {}, (err, cursor)=>
        @findAccounts cursor, [], (items) ->
          JAccount = require './account'
          JAccount.some { "_id": { "$in": items } }, {}, (err, jAccounts) =>
            callback err,jAccounts

  @ruleSplit:(rule, userCounts)->
    operators =
        '>': (badgeValue, userValue)-> return userValue > badgeValue
        '<': (badgeValue, userValue)-> return userValue < badgeValue
    #TODO : should use regular expressions
    actionPos = rule.search /[\<\>\=]/
    action    = rule.substr actionPos, 1
    property  = rule.substr 0,actionPos
    propVal   = rule.substr actionPos+1

    if not operators[action] propVal, userCounts[property] then no else yes

  @checkRules : (rules, userCounts)->
    ruleArray = rules.split "+"
    if ruleArray.length > 1
      for rule in ruleArray
        if not @ruleSplit rule,userCounts then return no
    else
      if not @ruleSplit rules,userCounts then return no
    yes


  @checkEligibleBadges:secure (client, options, callback) ->
    {badgeItem}  = options
    {@delegate}  = client.connection
    userCounts   = @delegate.counts
    if @delegate.type is 'unregistered' then return callback new KodingError 'Access denied'
    #get user badges
    @delegate.fetchBadges (err, userBadges)=>
      badgeIds = (userBadge.getId() for userBadge in userBadges)
      # find badges that users can gain and not already gained
      @listBadges client, {"rule":{"$regex":badgeItem}, "_id":{$nin:badgeIds}}, (err, badges)=>
        badgesGained  = []
        errors        = []
        queue = badges.map (badge) =>=>
          if @checkRules badge.rule, userCounts
              @delegate.addBadge badge, (err, o)->
                errors.push err if err
                badgesGained.push badge
                queue.next()
          else
            queue.next()
        queue.push -> callback if errors.length > 0 then null else badgesGained
        daisy queue
