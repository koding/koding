jraphical = require 'jraphical'

module.exports = class JFeed extends jraphical.Module
  {secure} = require 'bongo'
  @set
    schema:
      title:
        type: String
        required: yes
      description: String
      owner:
        type: String
        required: yes
      meta: require 'bongo/bundles/meta'
    relationships:
      content       :
        as          : 'container'
        targetType  : ["CActivity", "JStatusUpdate", "JCodeSnip", "JComment"]

  @createFeed = (account, options, callback) ->
    {title, description} = options
    feed = new JFeed {
      title
      description
      owner: account.profile.nickname
    }
    feed.save (err) ->
      if err
        callback err
      else
        account.addFeed feed, (err) ->
          if err
            callback err
          else
            callback null, feed