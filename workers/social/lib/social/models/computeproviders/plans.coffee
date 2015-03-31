{clone}              = require 'underscore'
module.exports       = clone
  free               :
    total            : 1
    alwaysOn         : 0
    storage          : 3
    allowedInstances : ['t2.micro']
    managed          : 1
  hobbyist           :
    total            : 1
    alwaysOn         : 1
    storage          : 10
    allowedInstances : ['t2.micro']
    managed          : 2
  developer          :
    total            : 3
    alwaysOn         : 1
    storage          : 25
    allowedInstances : ['t2.micro']
    managed          : 3
  professional       :
    total            : 5
    alwaysOn         : 2
    storage          : 50
    allowedInstances : ['t2.micro']
    managed          : 5
  super              :
    total            : 10
    alwaysOn         : 5
    storage          : 100
    allowedInstances : ['t2.micro']
    managed          : 10
  koding             :
    total            : 20
    alwaysOn         : 20
    storage          : 200
    allowedInstances : ['t2.micro', 't2.small', 't2.medium']
    managed          : 20
  betatester         :
    total            : 1
    alwaysOn         : 1
    storage          : 3
    allowedInstances : ['t2.micro']
    managed          : 0
