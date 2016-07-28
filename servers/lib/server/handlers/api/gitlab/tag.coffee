GenericHandler = require './generichandler'

module.exports = class Tag extends GenericHandler


  # event tag_push
  @push = (data, callback = -> ) ->

    try

      { ref
        user_email
        checkout_sha
      } = data

      {
        name: project_name
        commits: project_commits
        path_with_namespace: project_path_with_namespace
      } = data.project

    catch e
      return callback { message: 'missing data', error: e }

    # IMPLEMENT ME

    callback { message: 'tag push handler is not implemented' }
