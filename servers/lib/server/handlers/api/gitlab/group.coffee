GenericHandler = require './generichandler'

module.exports = class Group extends GenericHandler


  # event group_create
  @create = (data, callback = -> ) ->
    { name
      path
      owner_email
      owner_name } = data

    # IMPLEMENT ME

    callback { message: 'group create handler is not implemented' }


  # event group_destroy
  @destroy = (data, callback = -> ) ->
    { name
      path
      owner_email
      owner_name } = data

    # IMPLEMENT ME

    callback { message: 'group destroy handler is not implemented' }
