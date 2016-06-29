GenericHandler = require './generichandler'

module.exports = class Project extends GenericHandler


  # event project_create
  @create = (data, callback = -> ) ->
    { name
      owner_email
      path_with_namespace
      project_visibility } = data

    # IMPLEMENT ME

    callback { message: 'project create handler is not implemented' }


  # event project_destroy
  @destroy = (data, callback = -> ) ->
    { name
      owner_email
      path_with_namespace
      project_visibility } = data

    # IMPLEMENT ME

    callback { message: 'project destroy handler is not implemented' }


  # event project_rename
  @rename = (data, callback = -> ) ->
    { name
      owner_email
      path_with_namespace
      old_path_with_namespace
      project_visibility } = data

    # IMPLEMENT ME

    callback { message: 'project rename handler is not implemented' }


  # event project_transfer
  @transfer = (data, callback = -> ) ->
    { name
      owner_email
      path_with_namespace
      old_path_with_namespace
      project_visibility } = data

    # IMPLEMENT ME

    callback { message: 'project transfer handler is not implemented' }
