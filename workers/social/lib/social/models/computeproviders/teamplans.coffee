{ clone } = require 'underscore'

BASIC_RESTRICTIONS     =
  supports             : [ 'provider', 'resource' ]
  provider             : [ 'aws' ]
  resource             : [ 'aws_instance' ]
  custom               :
    ami                : no
    tags               : no
    user_data          : yes

module.exports = clone

  default              :
    member             : 1  # max number, can be overwritten in group data
                            # by a super-admin (an admin in Koding group)
    validFor           : 0  # no expire date
    instancePerMember  : 1  # allows one instance per member
    allowedInstances   : [ 't2.micro' ]
    maxInstance        : 1  # maximum instance count for this group (total)
    storagePerInstance : 5  # means 5GB storage for this plan in total (max).
                            # 1 member x 1 instancePerMember = 1 instance
                            # 5GB per instance x 1 instances = 5GB in total
    restrictions       : BASIC_RESTRICTIONS

  trial                :
    member             : 5  # max number, can be overwritten in group data
                            # by a super-admin (an admin in Koding group)
    validFor           : 30 # in days (1 month)
    instancePerMember  : 1  # allows one instance per member
    allowedInstances   : [ 't2.micro' ]
    maxInstance        : 10 # maximum instance count for this group (total)
    storagePerInstance : 5  # means 25GB storage for this plan in total (max).
                            # 5 member x 1 instancePerMember = 5 instances
                            # 5GB per instance x 5 instances = 25GB in total
    restrictions       : BASIC_RESTRICTIONS

  basic                :
    member             : 5  # max number, can be overwritten in group data
                            # by a super-admin (an admin in Koding group)
    validFor           : 30 # in days (1 month)
    instancePerMember  : 2  # allows two instances per member
    allowedInstances   : [ 't2.micro', 't2.small' ]
    maxInstance        : 20 # maximum instance count for this group (total)
    storagePerInstance : 10 # means 100GB storage for this plan in total (max).
                            # 5 member x 2 instancePerMember   = 10 instances
                            # 10GB per instance x 10 instances = 100GB in total
    restrictions       : BASIC_RESTRICTIONS

  superior             :
    member             : 50
    validFor           : 30
    instancePerMember  : 5
    allowedInstances   : [
      't2.micro', 't2.small', 't2.medium', 't2.large'
      'm3.medium', 'm3.large', 'c3.large', 'c3.xlarge'
    ]
    maxInstance        : 500
    storagePerInstance : 20
    restrictions       : BASIC_RESTRICTIONS

  unlimited            :    # sky is the limit
    member             : 5000
    validFor           : 0  # no expire date
    instancePerMember  : 90 # enough to run koding
    allowedInstances   : [] # all types of instances are allowed
    maxInstance        : 9000
    storagePerInstance : 1000
    restrictions       : {}
