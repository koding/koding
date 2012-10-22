###
function ensureuserFeeds (Array feeds) -> void()
feeds = [feed]
feed = {title, description}
###

JAccount  = require './models/account'
JFeed     = require './models/feed'

JAccount.someData {}, {}, (err, cursor) ->
if err
  console.log "Error finding users"
else
  cursor.each (err, doc) ->
    account = new JAccount doc
    for feedInfo in feeds
      JFeed.assureFeed account, feedInfo, (err, feed) ->