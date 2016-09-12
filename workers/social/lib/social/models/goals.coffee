t = require './trackingtypes'

g = {}
g[t.FINISH_REGISTER] = 4
g[t.STACKS_MAKE_DEFAULT] = 6
g[t.STACKS_BUILD_SUCCESSFULLY] = 8
g[t.TEAMS_SENT_INVITATION] = 10
g[t.LOGGED_IN] = 22


module.exports =

  goalMap : g

  getGoalId : (event) -> g[event] ? null

  getProps : (event) ->

    return {}  unless goal_id = @getGoalId event

    return { goal_id }
