KodingError = require '../../error'


validateResizeByUserPlan = (resize, userPlan) ->

  if isNaN resize
    return new KodingError \
    'Requested new size is not valid.', 'WrongParameter'
  else if resize > userPlan.storage
    return new KodingError \
    """Requested new size exceeds allowed
       limit of #{userPlan.storage}GB.""", 'UsageLimitReached'
  else if resize < 3
    return new KodingError \
    """New size can't be less than 3GB.""", 'WrongParameter'


validateResizeByMachine = (options) ->

  { resize, storageSize, usage, userPlan, machine } = options

  if (resize - storageSize) + usage.storage > userPlan.storage
    return new KodingError \
    """Requested new size exceeds allowed
       limit of #{userPlan.storage}GB.""", 'UsageLimitReached'
  else if resize is machine.getAt 'meta.storage_size'
    return new KodingError \
    """Requested new size is same with current
       storage size (#{resize}GB).""", 'SameValueForResize'


updateMachine = (options, callback) ->

  JMachine = require './machine'
  { selector, alwaysOn, resize, usage, userPlan } = options

  JMachine.one selector, (err, machine) ->

    if err? or not machine?
      err ?= new KodingError 'Machine object not found.'
      return callback err

    fieldsToUpdate = {}

    if alwaysOn?
      fieldsToUpdate['meta.alwaysOn'] = alwaysOn

    if resize?
      storageSize = machine.meta?.storage_size ? 3

      _options = { resize, storageSize, usage, userPlan, machine }
      if err = validateResizeByMachine _options
        return callback err

      fieldsToUpdate['meta.storage_size'] = resize

    machine.update { $set: fieldsToUpdate }, (err) ->
      callback err


getPlanConfig = (group) ->

  return {
    plan      : 'unlimited'
    overrides : group.getAt 'config.planOverrides'
  }


module.exports = { updateMachine, validateResizeByMachine, validateResizeByUserPlan, getPlanConfig }
