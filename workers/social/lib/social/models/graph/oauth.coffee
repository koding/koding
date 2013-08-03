{Graph} = require './index'
QueryRegistry = require './queryregistry'

module.exports = class OAuth extends Graph

  # todo refactor here according to new structure
  ## NEWER IMPLEMENATION: Fetch ids from graph db, get items from document db.
  @fetchRelatedTagsFromGraph: (options, callback)->
    {userId} = options

    query = """
            START follower=node:koding("id:#{userId}")
            MATCH follower-[:related]->oauth-[r:github_followed_JTag]->followees
            return followees.id as id
            """

    JTag = require "../tag"
    @fetchItems query, JTag, callback

  @fetchRelatedUsersFromGraph: (options, callback)->
    {userId} = options

    query = """
            START follower=node:koding("id:#{userId}")
            MATCH follower-[:related]->oauth-[r:github_followed_JUser]->followees
            return followees.id as id
            """
    JUser = require "../user"
    @fetchItems query, JUser, callback


  @fetchItems:(query, modelName, callback)->
    @fetch query, {}, (err, results)=>
      if err then throw err
      else
        tempRes = []
        collectContents = race (i, id, fin)=>
          modelName.one  { _id : id }, (err, account)=>
            if err
              callback err
              fin()
            else
              tempRes[i] =  account
              fin()
        , ->
          callback null, tempRes
        for res in results
          collectContents res.id
