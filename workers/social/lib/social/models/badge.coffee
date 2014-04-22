jraphical = require 'jraphical'
module.exports = class JBadge extends jraphical.Module
  {permit}          = require './group/permissionset'
  {daisy, secure, signature}   = require 'bongo'
  KodingError       = require '../error'

  @trait __dirname, '../traits/filterable'
  @trait __dirname, '../traits/protected'

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
    sharedEvents          :
      instance            : []
      static              : []
    sharedMethods         :
      static :
        listBadges :
          (signature Object, Object, Function)
        create :
          (signature Object, Function)
        fetchBadgeUsers :
          (signature String, Object, Function)
        checkEligibleBadges :
          (signature Object, Function)
      instance :
        modify :
          (signature Object, Function)
        deleteBadge :
          (signature Function)
        removeBadgeFromUser :
          (signature Object, Function)
        assignBadgeBatch :
          (signature Object, Function)

# We dont assign current roles, because on badge remove, it deletes
# roles and its users also. If role has users before badge assignment
# they also will be removed.
  @create: permit 'create badge',
    success:(client, badgeData, callback=->)->
      protectedRoles = ["admin","owner","guest","member"]
      unless badgeData.role in protectedRoles
        badge = new JBadge badgeData
        badge.role = null if badgeData.role is "none"
        badge.save (err)=>
          callback err, badge
      else
        callback new KodingError 'That role cannot be given from UI', null

  @listBadges: permit 'list badges',
    success: (client, selector, options, callback=->)->
      JBadge.some selector, options, callback

  modify: permit 'edit badge',
    success: (client, formData, callback)->
      updatedFields =
        title       : formData.title
        iconURL     : formData.iconURL
        description : formData.description

      @update $set  :updatedFields, callback

  deleteBadge : permit 'delete badge',
    success: (client, callback=->)->
      # get badge users
      JBadge.fetchBadgeUsers client, @getId(), {}, (err, accounts)=>
        return err if err
        ids = (account.getId() for account in accounts)
        removeKey = "$in" : ids
        # remove role that given with that badge
        jraphical.Relationship.remove {
          sourceName : "JGroup"
          as         : @role
          targetId   : removeKey
        },(err)=>
          return err if err
          # remove badge
          @remove (err)->
            return callback err, null

  assignBadgeBatch : permit 'assign badge',
    success: (client, accountIds, callback)->
      if accountIds.length > 0
        JAccount = require './account'
        queue    = accountIds.map (id) =>=>
          JAccount.one "_id" : id, (err, account)=>
            return queue.next() if err or not account
            jraphical.Relationship.one
              as         : "badge"
              targetId   : @getId()
              sourceId   : account.getId()
            , (err, rel) =>
                return queue.next() if err or rel
                account.addBadge this, (err, badge)=>
                  return queue.next() if err or not badge
                  groupName = client.context.group
                  # find the group id
                  JGroup = require './group'
                  JGroup.one {slug : groupName}, (err, group)=>
                    return queue.next() if err or @role is undefined
                    new jraphical.Relationship
                      targetName  : 'JAccount'
                      targetId    : account.getId()
                      sourceName  : 'JGroup'
                      sourceId    : group.getId()
                      as          : @role
                    .save (err)=>
                      queue.next()
        queue.push -> callback null
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
        return callback err if err
        Relationship.remove {
          targetId   : user._id
          targetName : 'JAccount'
          sourceName : "JGroup"
          as         : @role
        }, callback

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
    success: (client, badgeId, options, callback)->
      selector =
        targetName : "JBadge"
        targetId   : badgeId
        as         : "badge"
        sourceName : "JAccount"

      jraphical.Relationship.cursor selector, options, (err, cursor)=>
        return callback err if err
        @findAccounts cursor, [], (items) ->
          JAccount = require './account'
          JAccount.some { "_id": { "$in": items } }, {}, callback

  @ruleSplit:(rule, userCounts)->
    operators =
        '>': (badgeValue, userValue)-> userValue > badgeValue
        '<': (badgeValue, userValue)-> userValue < badgeValue
    #TODO : should use regular expressions
    actionPos = rule.search /[\<\>\=]/ # find the position of "<,>,=" in rule
    action    = rule.substr actionPos, 1
    property  = rule.substr 0, actionPos
    propVal   = rule.substr actionPos + 1

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
      return err if err
      badgeIds = []
      if userBadges then badgeIds = (userBadge.getId() for userBadge in userBadges)
      # find badges that users can gain and not already gained
      ruleSelector =
        "rule"     :
          "$regex" : options.badgeItem
        "_id"      : $nin:badgeIds
      # 50 is hardcoded, we may need to get this value from client.
      JBadge.some ruleSelector,{limit:50}, (err, badges)=>
        return err if err
        badgesGained  = []
        queue = badges.map (badge) =>=>
          return queue.next() if not @checkRules badge.rule, @account.counts
          @account.addBadge badge, (err, o)->
            return queue.next() if err
            JGroup = require './group'
            {context:{group:groupName}} = client
            JGroup.one {slug : groupName}, (err, group)=>
              return queue.next() if err or not group
              user = client.connection.delegate
              if badge.role
                new jraphical.Relationship
                  targetName  : 'JAccount'
                  targetId    : user.getId()
                  sourceName  : 'JGroup'
                  sourceId    : group.getId()
                  as          : badge.role
                .save (err)=>
                  return queue.next() if err
                  badgesGained.push badge
                  queue.next()
              else
                badgesGained.push badge
                queue.next()
        queue.push -> callback null, badgesGained
        daisy queue
