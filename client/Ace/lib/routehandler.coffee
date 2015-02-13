kd = require 'kd'
lazyrouter = require 'app/lazyrouter'

module.exports = -> lazyrouter.bind 'ace', (type, info, state, path, ctx) ->

  switch type
    when 'redirect'
      kd.singletons.router.handleRoute path.replace(/\/Ace/, '/IDE')
