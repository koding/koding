kd = require 'kd'

# TODO: Not totally sure what this is supposed to do, but I put it here
#       to bypass awful hacks by Arvid Kahl:
module.exports = (type) ->
  switch type
    when 'audio', 'xml', 'json', 'ppt', 'rss', 'atom'
      return 'object'

    # this is usually just a single image
    when 'photo','image'
      return 'image'

    when 'video'
      return 'video'

    when 'link', 'html'
      return 'link'

    # embedly supports many error types. we could display those to the user
    when 'error'
      kd.log 'Embedding error '
      return 'error'

    else
      kd.log "Unhandled content type '#{type}'"
      return 'error'
