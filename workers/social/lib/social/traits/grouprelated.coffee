module.exports = class GroupRelated

  @onTraitAdded: ->
    JGroup = require '../models/group'
    JGroup.on 'GroupDestroyed', (group) =>
      @remove { group: group.slug }, (err) ->
        console.error err  if err
