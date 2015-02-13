kd = require 'kd'
KDListItemView = kd.ListItemView
module.exports = class AccountNavigationItem extends KDListItemView

  constructor:(options = {}, data)->

    options.tagName    = 'a'
    options.attributes = href : "/Account/#{data.slug}"

    super options, data

    @name = @getData().title

  partial:(data)-> data.title


