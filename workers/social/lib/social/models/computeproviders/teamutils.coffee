KodingError = require '../../error'
TEAMPLANS   = require './teamplans'

konstraints = require 'konstraints'
_           = require 'underscore'
JGroupPlan  = require '../group/groupplan'


shareCredentials = (options, callback) ->

  { account, group } = options

  return callback null  unless group.config?.plan?

  JCredential = require './credential'
  JCredential.one { 'meta.trial': yes }, (err, credential) ->

    if err or not credential
      err ?= new KodingError 'No credential found to share with team'
      return callback err

    scope = { user: yes, owner: no, role: 'admin' }

    # Share with the group so everyone in this group
    # can build stack with this credential
    #
    # But also provide role as admin so admins can see
    # this credential in their credentials list

    credential.setPermissionFor group, scope, callback


# Returns plan data
# If plan is not found, it fallbacks to default
# If there are plan overrides, they override plan properties
getPlanData = (planConfig, callback) ->

  { plan, overrides } = planConfig

  if plan in Object.keys TEAMPLANS
    result = _.extend {}, TEAMPLANS[plan], (overrides ? {})
    return callback null, result

  JGroupPlan.one { name: plan }, (err, planData) ->
    return callback err  if err
    return callback null, TEAMPLANS['default']  unless planData
    return callback null, planData


# Takes plan config as reference and generates valid konstraint
# rules based on the TEAMPLANS data ~ GG
generateConstraints = (planConfig, callback) -> getPlanData planConfig, (err, plan) ->

  return callback err  if err

  # First rule be an object.
  rules = [ { $typeof : 'object' } ]

  # Get plan data
  { member, validFor, instancePerMember, restrictions
    allowedInstances, storagePerInstance } = plan

  # Add restrictions if exists
  if (Object.keys restrictions).length > 0

    { supports, provider, resource, custom } = restrictions

    if supports?
      rules.push { $keys: supports }

    if provider?
      rules.push { 'provider': [{ $typeof: 'object' }, { $keys: provider }] }

      # don't allow any custom keys to define for aws provider
      rules.push { 'provider.aws': [{ $typeof: 'object' }, { $length: 2 }] }

      # we are expecting that we use aws_ related variables here
      rules.push {
        'provider.aws.access_key': { $eq: '${var.aws_access_key}' }
      }
      rules.push {
        'provider.aws.secret_key': { $eq: '${var.aws_secret_key}' }
      }

    if resource?
      rules.push { 'resource': [{ $typeof: 'object' }, { $keys: resource }] }


  # Add instance limit per user
  rules.push { 'resource.aws_instance?': [
                { $typeof: 'object' },
                { $length: { $lte: instancePerMember } }
            ] }

  # Custom restrictions
  if restrictions?.custom?

    { ami, tags, user_data } = restrictions.custom

    allowedKeys = [ 'tags', 'instance_type', 'ami', 'root_block_device' ]
    allowedKeys.push 'user_data'  if user_data

    rules.push { 'resource.aws_instance.*': { $keys: allowedKeys } }

    unless tags
      # This is the default instance name in AWS Console
      # so we are not allowing custom tag definitions here
      # TODO this can be taken from config ~ GG
      instanceName = '${var.koding_user_username}-${var.koding_group_slug}'
      rules.push { 'resource.aws_instance.*.tags': [
                    { $keys: ['Name'] }
                    { Name: { $eq: instanceName } }
                ] }

  # Add allowed instance types if defined
  if allowedInstances.length > 0
    rules.push { 'resource.aws_instance.*.instance_type': [
                   { $typeof: 'string' }
                   { $in: allowedInstances }
              ] }

  # Add storage limit per instance, this checks are optional
  # we don't need to define volume_size in each stack template
  # but when we do we need to fit with the rules ~ GG
  rules.push { 'resource.aws_instance.*.root_block_device': [
                 { 'volume_size?': { $typeof: 'number' } }
                 { 'volume_size?': { $lte: storagePerInstance } }
                 { 'volume_size?': { $gte: 3 } }  # min volume size 3GB
            ] }

  callback null, rules


module.exports = {
  generateConstraints, getPlanData, shareCredentials, TEAMPLANS
}
