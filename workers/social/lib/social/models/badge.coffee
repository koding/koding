jraphical = require 'jraphical'
module.exports = class JBadge extends jraphical.Module
  {permit}          = require './group/permissionset'
  {daisy, secure}   = require 'bongo'
  KodingError       = require '../error'

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
      role                : String # storing as string because we already use permission title as a relation identifier in relationship modal
      createdAt           :
        type              : Date
        default           : -> new Date
    sharedMethods         :
      static              : ["listBadges", "create","fetchBadgeUsers",
      "checkEligibleBadges"]
      instance            : ["modify", "deleteBadge","removeBadgeFromUser",
      "assignBadgeBatch"]

  @create: permit 'create badge',
    success:(client, badgeData, callback=->)->
      protectedRoles = ["admin","moderator","owner","guest","member"]
      unless badgeData.role in protectedRoles
        badge = new JBadge badgeData
        badge.save (err)=>
          callback err, badge
      else
        callback new KodingError 'That role cannot be given from UI', null

  @listBadges: permit 'list badges',
    success: (client, selector, callback=->)->
      JBadge.some selector,{limit:50},callback

  modify: permit 'edit badge',
    success: (client, formData, callback)->
      @update $set : formData, callback

  deleteBadge : permit 'delete badge',
    success: (client, callback=->)->
      @remove (err)=>
        unless err
          jraphical.Relationship.remove {
            sourceName : "JGroup"
            as         : @role
          },(err)->
          return callback err if err
          return callback null, null

  assignBadgeBatch : permit 'assign badge',
    success: (client, accountIds, callback)->
      if accountIds.length > 0
        JAccount = require './account'
        errors   = []
        queue    = accountIds.map (id) =>=>
          JAccount.one "_id" : id, (err, account)=>
            errors.push err if err
            if account
              jraphical.Relationship.one
                as         : "badge"
                targetId   : @getId()
                sourceId   : account.getId()
              , (err, rel) =>
                  unless rel
                    account.addBadge this, (err, badge)=>
                      errors.push err if err
                      groupName = client.context.group
                      # find the group id
                      JGroup = require './group'
                      JGroup.one {slug : groupName}, (err, group)=>
                        unless err
                          new jraphical.Relationship
                            targetName  : 'JAccount'
                            targetId    : account.getId()
                            sourceName  : 'JGroup'
                            sourceId    : group.getId()
                            as          : @role
                          .save (err)=>
                            errors.push err if err
                            queue.next()
                        else
                          errors.push err if err
                          queue.next()
                  else
                    queue.next()
            else
              queue.next()
        queue.push -> callback if errors.length > 0 then errors else null
        daisy queue

  removeBadgeFromUser : permit 'remove user badge',
    success: (client, user, callback)->
      {Relationship} = jraphical
      Relationship.remove {
        targetId   : @getId()
        targetName : 'JBadge'
        sourceId   : user._id
        sourceName : 'JAccount'
        as         : "badge"
      }, (err)=>
        unless err
          Relationship.remove {
            targetId   : user._id
            targetName : 'JAccount'
            sourceName : "JGroup"
            as         : @role
          }, (err)->
            callback err, null


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
    success: (client, badgeId, selector,callback)->
      query =
        targetName : "JBadge"
        targetId   : badgeId
        as         : "badge"
        sourceName : "JAccount"

      jraphical.Relationship.cursor query, selector, (err, cursor)=>
        @findAccounts cursor, [], (items) ->
          JAccount = require './account'
          JAccount.some { "_id": { "$in": items } }, {}, (err, jAccounts) =>
            callback err,jAccounts

  @ruleSplit:(rule, userCounts)->
    operators =
        '>': (badgeValue, userValue)-> userValue > badgeValue
        '<': (badgeValue, userValue)-> userValue < badgeValue
    #TODO : should use regular expressions
    actionPos = rule.search /[\<\>\=]/
    action    = rule.substr actionPos, 1
    property  = rule.substr 0,actionPos
    propVal   = rule.substr actionPos+1

    operators[action] propVal, userCounts[property]

  @checkRules : (rules, userCounts)->
    ruleArray = rules.split "+"
    if ruleArray.length is 1
      return @ruleSplit rules, userCounts
    else
      for rule in ruleArray
        return no  unless @ruleSplit rule, userCounts
      return yes


  @checkEligibleBadges:secure (client, options, callback) ->
    @account  = client.connection.delegate
    #get user badges
    @account.fetchBadges (err, userBadges)=>
      badgeIds =[]
      if userBadges then badgeIds = (userBadge.getId() for userBadge in userBadges)
      # find badges that users can gain and not already gained
      ruleSelector =
        "rule"     :
          "$regex" : options.badgeItem
        "_id"      : $nin:badgeIds
      JBadge.some ruleSelector,{limit:50}, (err, badges)=>
        badgesGained  = []
        errors        = []
        queue = badges.map (badge) =>=>
          if @checkRules badge.rule, @account.counts
            @account.addBadge badge, (err, o)->
              JGroup = require './group'
              groupName = client.context.group
              JGroup.one {slug : groupName}, (err, group)=>
                user = client.connection.delegate
                unless err
                  if badge.role
                    new jraphical.Relationship
                      targetName  : 'JAccount'
                      targetId    : user.getId()
                      sourceName  : 'JGroup'
                      sourceId    : group.getId()
                      as          : badge.role
                    .save (err)=>
                      errors.push err if err
                      badgesGained.push badge
                      queue.next()
                  else
                    badgesGained.push badge
                    queue.next()
                else
                  errors.push err if err
                  queue.next()
          else
            queue.next()
        queue.push -> callback if errors.length > 0 then null else badgesGained
        daisy queue
