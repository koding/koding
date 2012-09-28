{error, execute} = require './helpers'

module.exports = (vhost, config, callback)->
  execute "rabbitmqctl delete_vhosts", (stdout)->
    callback null