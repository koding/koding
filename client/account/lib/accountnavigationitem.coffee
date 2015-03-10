kd = require 'kd'
KDListItemView = kd.ListItemView
module.exports = class AccountNavigationItem extends KDListItemView

  constructor:(options = {}, data)->

    options.tagName    = 'a'
    options.attributes = href : "/Account/#{data.slug}"
    options.cssClass   = "AppModal-navItem #{data.slug.toLowerCase()}"

    super options, data

    @name = @getData().title

  partial:(data)-> data.title


