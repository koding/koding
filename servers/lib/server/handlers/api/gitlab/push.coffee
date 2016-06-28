GenericHandler = require './generichandler'

module.exports = class Push extends GenericHandler


  # event push_main
  @main = (data, callback = ->) ->
    {
     ref
     user_email
     checkout_sha
     project: { name: project_name }
     project: { path_with_namespace: project_path_with_namespace }
     project: { commits: project_commits }
    } = data

    # IMPLEMENT ME

    callback { message: 'push main handler is not implemented' }
