ActivityListController = require 'activity/activitylistcontroller'

module.exports = class MemberActivityListController extends ActivityListController
  # used for filtering received live updates
  addItem: (activity, index, animation) ->
    if activity.account._id is @getOptions().creator.getId()
      super activity, index, animation
