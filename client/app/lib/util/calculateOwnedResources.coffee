debug = require('debug')('util:calculateOwnedResources')
{ flatten } = require 'lodash'


module.exports = calculateOwnedResources = (props, state) ->

  debug 'start calculating own resources', { props, state }

  # first get stacks of templates we own.
  resources = props.templates.map (template) ->

    stacks = props.stacks.filter (s) -> s.baseStackId is template.getId()

    unless stacks.length
      return [{ stack: null, template, unreadCount: 0 }]

    return stacks.map (stack) -> { stack, template, unreadCount: 0 }


  debug 'resources are calculated before flatten', resources

  # this will make sure that stacks will be on top,
  # 1) all stacks created from the same template will be grouped & flattened,
  # 2) the templates without stacks will come after them.
  resources = flatten(resources).sort ({ stack }) -> if stack then -1 else 1

  [ managedStack ] = props.stacks.filter (s) ->
    s.title.indexOf('Managed VMs') > -1

  # and finally show managed machines on bottom.
  if managedStack and managedStack.machines?.length
    resources.push { stack: managedStack, template: null, unreadCount: 0 }

  debug 'owned resources are calculated', resources

  return resources
