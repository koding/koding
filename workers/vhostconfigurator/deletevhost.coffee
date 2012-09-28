{error, execute} = require './helpers'

module.exports = (vhost, config, callback)->
  execute "rabbitmqctl delete_vhost #{vhost}", (stdout)->
    callback null