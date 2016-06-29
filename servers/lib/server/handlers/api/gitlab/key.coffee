GenericHandler = require './generichandler'

module.exports = class Key extends GenericHandler


  # event key_create
  @create = (data, callback = -> ) ->
    { username
      key } = data

    # IMPLEMENT ME

    callback { message: 'key create handler is not implemented' }


  # event key_destroy
  @destroy = (data, callback = -> ) ->
    { username
      key } = data

    # IMPLEMENT ME

    callback { message: 'key destroy handler is not implemented' }
