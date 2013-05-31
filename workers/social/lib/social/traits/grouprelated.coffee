module.exports = class GroupRelated

  @onTraitAdded:->
    JGroup = require '../models/group'
    JGroup.on 'GroupDestroyed', (group, callback)=>
      @remove group: group.slug, callback