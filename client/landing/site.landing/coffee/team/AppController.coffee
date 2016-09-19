kd       = require 'kd'
utils    = require './../core/utils'
TeamView = require './AppView'

FLOW_ROUTES  =
  'signup'        : '/Teams'
  'domain'        : '/Team/Domain'
  'username'      : '/Team/Username'
  'join'          : '/Team/Join'
  'register'      : '/Team/Register'
  # 'welcome'       : '/Team/Welcome'
  # 'email-domains' : '/Team/Email-domains'
  # 'invite'        : '/Team/Invite'
  # 'stacks'        : '/Team/Stacks'
  # 'congrats'      : '/Team/Congrats'

# 'email-domains' and 'invite' left out intentionally
CREATION_FLOW = [ 'signup', 'domain', 'username' ]
# JOIN_FLOW     = [ 'welcome', 'join' ]


getFlow = (step) ->

  # return JOIN_FLOW     if JOIN_FLOW.indexOf(step) > -1
  return CREATION_FLOW if CREATION_FLOW.indexOf(step) > -1
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

    options.view = new TeamView { cssClass : 'Team Team--ufo content-page' }

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
