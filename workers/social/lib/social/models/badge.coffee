jraphical = require 'jraphical'
module.exports = class JBadge extends jraphical.Module
  {permit}          = require './group/permissionset'

  @trait __dirname, '../traits/filterable'

  @share()
  @set
    permissions           :
      'create badge'      : []
      'delete badge'      : []
      'edit badge'        : []
      'assign badge'      : ['moderator']
      'list badges'       : ['moderator']
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
      static              : ["listBadges", "getUserBadges","create"]
      instance            : ["modify","deleteBadge","assignBadge","removeBadgeFromUser"]

  @create: permit 'create badge',
    success:(client, badge, callback=->)->
      {title, description, rules, invisible, iconURL, reward} = badge
      badge = new JBadge {title, description, rules, invisible, iconURL, reward}
      badge.save (err)=>
        callback err, badge

  @listBadges: permit 'list badges',
    success: (client, selector, callback=->)->
      JBadge.some selector,{},callback

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
      JAccount.one {'profile.nickname' : user.profile.nickname}, (err, account)=>
        account.addBadge this, callback

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
    JAccount.one {'profile.nickname' : user.profile.nickname}, (err, account)=>
        account.fetchBadges callback

