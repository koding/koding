GenericHandler = require './generichandler'

module.exports = class User extends GenericHandler


  # event user_create
  @create = (data, callback = -> ) ->
    { username
      email
      name } = data

    # IMPLEMENT ME

    callback { message: 'user create handler is not implemented' }


  # event user_destroy
  @destroy = (data, callback = -> ) ->
    { username
      email
      name } = data

    # IMPLEMENT ME

    callback { message: 'user destroy handler is not implemented' }


  # event user_add_to_team
  @add_to_team = (data, callback = -> ) ->
    { project_path_with_namespace
      user_username
      user_email } = data

    # IMPLEMENT ME

    callback { message: 'user add_to_team handler is not implemented' }


  # event user_remove_from_team
  @remove_from_team = (data, callback = -> ) ->
    { project_path_with_namespace
      user_username
      user_email } = data

    # IMPLEMENT ME

    callback { message: 'user remove_from_team handler is not implemented' }


  # event user_add_to_group
  @add_to_group = (data, callback = -> ) ->
    { group_path
      group_access
      user_name
      user_email
      user_username } = data

    # IMPLEMENT ME

    callback { message: 'user add_to_group handler is not implemented' }


  # event user_remove_from_group
  @remove_from_group = (data, callback = -> ) ->
    { group_path
      group_access
      user_name
      user_email
      user_username } = data

    # IMPLEMENT ME

    callback { message: 'user remove_from_group handler is not implemented' }
