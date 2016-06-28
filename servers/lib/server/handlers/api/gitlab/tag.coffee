GenericHandler = require './generichandler'

module.exports = class Tag extends GenericHandler


  # event tag_push
  @push = (data, callback = ->) ->
    {
     ref
     user_email
     checkout_sha
     project: { name: project_name }
     project: { path_with_namespace: project_path_with_namespace }
     project: { commits: project_commits }
    } = data

    # IMPLEMENT ME

    callback { message: 'tag push handler is not implemented' }
