GenericHandler = require './generichandler'

module.exports = class Push extends GenericHandler


  # event push_main
  @main = (data, callback = -> ) ->
    { ref
      user_email
      checkout_sha
    } = data

    {
      name: project_name
      commits: project_commits
      path_with_namespace: project_path_with_namespace
    } = data.project

    # IMPLEMENT ME

    callback { message: 'push main handler is not implemented' }
