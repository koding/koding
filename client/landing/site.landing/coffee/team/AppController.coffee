TeamView = require './AppView'

FLOW_ROUTES  =
  'signup'        : '/Teams'
  'domain'        : '/Team/Domain'
  'email-domains' : '/Team/Email-domains'
  'invite'        : '/Team/Invite'
  'username'      : '/Team/Username'
  'stacks'        : '/Team/Stacks'
  'welcome'       : '/Team/Welcome'
  'join'          : '/Team/Join'
  'congrats'      : '/Team/Congrats'

CREATION_FLOW = [ 'signup', 'domain', 'email-domains', 'invite'
                  'username', 'stacks', 'congrats' ]
JOIN_FLOW     = [ 'welcome', 'join' ]


getFlow = (step) ->

  return JOIN_FLOW     if JOIN_FLOW.indexOf(step) > -1
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
    unless KD.utils.getTeamData()[step]
      result = no
      break

  return result


module.exports = class TeamAppController extends KDViewController

  KD.registerAppClass this,
    name : 'Team'

  constructor: (options = {}, data) ->

    options.view = new TeamView cssClass : 'Team content-page'

    super options, data


  jumpTo: (step, query) ->

    return  unless step

    flow = getFlow(step)
    if flow and not isPreviousStepCompleted flow, step
      prevStep = getPreviousStep flow, step
      KD.singletons.router.handleRoute getRouteFromStep prevStep
      return

    appView = @getView()
    appView.showTab step, query