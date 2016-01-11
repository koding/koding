kd = require 'kd'
KDView = kd.View
module.exports = class AccountEditorTags extends KDView
  viewAppended:->
    @setPartial @partial @data

  partial:(data)->
    extHTMLArr = for extension in data
      "<span class='blacktag'>#{extension}</span>"
    """
      #{extHTMLArr.join("")}
    """
