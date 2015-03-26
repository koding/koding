whoami = require './whoami'

module.exports = (post) ->
    post         or= {}
    post.account or= {}
    post.account._id is whoami()._id and post.typeConstant not in ['join', 'leave']
