class EnvironmentItemJoint extends KDDiaJoint
  constructor:(options={}, data)->
    options.cssClass = 'environments-joint'
    options.size     = 4
    super options, data