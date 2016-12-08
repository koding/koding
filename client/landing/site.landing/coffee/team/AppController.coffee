kd       = require 'kd'
utils    = require './../core/utils'
TeamView = require './AppView'

FLOW_ROUTES  =
  'signup'        : '/Teams'
  'domain'        : '/Team/Domain'
  'username'      : '/Team/Username'
  'payment'       : '/Team/Payment'
  'join'          : '/Team/Join'
  'register'      : '/Team/Register'


DEFAULT_ENV_FLOW = [ 'signup', 'domain', 'username' ]
REGULAR_CREATE_FLOW = [ 'signup', 'domain', 'payment', 'username' ]

getFlow = (step) ->

  flow = if kd.config.environment is 'default'
  then DEFAULT_ENV_FLOW else REGULAR_CREATE_FLOW

  return flow if flow.indexOf(step) > -1
  return no


getRouteFromStep = (step) -> FLOW_ROUTES[step] or '/'

getPreviousStep = (flow, step) ->

  index = flow.indexOf step

  return no  unless index > 0
  return flow[index - 1]


isPreviousStepCompleted = (flow, step) ->

  index = flow.indexOf step

  return yes  unless index > -1

  result = yes
  for step in flow.slice(0, index)
    unless utils.getTeamData()[step]
      result = no
      break

  return result


module.exports = class TeamAppController extends kd.ViewController

  kd.registerAppClass this,
    name : 'Team'


  constructor: (options = {}, data) ->

    options.view = new TeamView { cssClass : 'Team content-page' }

    super options, data


  jumpTo: (step, query) ->

    return  unless step

    flow = getFlow(step)
    if flow and not isPreviousStepCompleted flow, step
      prevStep = getPreviousStep flow, step
      kd.singletons.router.handleRoute getRouteFromStep prevStep
      return

    appView = @getView()
    appView.showTab step, query
