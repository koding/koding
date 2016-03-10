_ = require 'lodash'
shortenText = require 'app/util/shortenText'
SharePopup = require 'app/sharepopup'


module.exports = class ActivitySharePopup extends SharePopup

  constructor: (options = {}, data) ->

    options.cssClass    = "share-popup"
    options.shortenText = true
    options.twitter     = @getTwitterOptions options
    options.newTab      = @getNewTabOptions options

    super options, data


  getTwitterOptions: (options) ->

    data = options.delegate.getData()
    {tags} = data

    if tags
      hashTags  = ("##{tag.slug}"  for tag in tags when tag?.slug)
      hashTags  = _.uniq(hashTags).join " "
      hashTags += " "
    else
      hashTags = ''

    {title, body} = data
    itemText  = shortenText title or body, maxLength: 100, minLength: 100
    shareText = "#{itemText} #{hashTags}- #{options.url}"

    return enabled: true, text: shareText


  getNewTabOptions: (options) ->

    return enabled: true, url: options.url
