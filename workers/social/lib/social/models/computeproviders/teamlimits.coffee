{ clone } = require 'underscore'

BASIC_RESTRICTIONS     =
  supports             : [ 'provider', 'resource', 'koding' ]
  provider             : [ 'aws' ]
  resource             : [ 'aws_instance' ]
  custom               :
    ami                : no
    tags               : no
    user_data          : yes

module.exports = clone

  test                 :
    member             : 1  # max number, can be overwritten in group data
                            # by a super-admin (an admin in Koding group)
    validFor           : 0  # no expire date
    instancePerMember  : 1  # allows one instance per member
    allowedInstances   : [ 't2.nano' ]
    maxInstance        : 1  # maximum instance count for this group (total)
    storagePerInstance : 5  # means 5GB storage in total (max).
                            # 1 member x 1 instancePerMember = 1 instance
                            # 5GB per instance x 1 instances = 5GB in total
    restrictions       : BASIC_RESTRICTIONS

  default              :
    member             : 5  # max number, can be overwritten in group data
                            # by a super-admin (an admin in Koding group)
    validFor           : 0  # no expire date
    instancePerMember  : 2  # allows two instances per member
    allowedInstances   : [ 't2.nano' ]
    maxInstance        : 10 # maximum instance count for this group (total)
    storagePerInstance : 50 # means 500GB storage in total (max).
                            # 5 members x 2 instancePerMember = 10 instances
                            # 50GB per instance x 10 instances = 500GB in total
    restrictions       : BASIC_RESTRICTIONS

  trial                :
    member             : 20
    validFor           : 21
    instancePerMember  : 20
    allowedInstances   : []
    maxInstance        : 100
    storagePerInstance : 50
    restrictions       : {}

  basic                :
    member             : 5  # max number, can be overwritten in group data
                            # by a super-admin (an admin in Koding group)
    validFor           : 30 # in days (1 month)
    instancePerMember  : 2  # allows two instances per member
    allowedInstances   : [ 't2.nano', 't2.micro', 't2.small' ]
    maxInstance        : 20 # maximum instance count for this group (total)
    storagePerInstance : 10 # means 100GB storage in total (max).
                            # 5 member x 2 instancePerMember   = 10 instances
                            # 10GB per instance x 10 instances = 100GB in total
    restrictions       : BASIC_RESTRICTIONS

  superior             :
    member             : 50
    validFor           : 30
    instancePerMember  : 5
    allowedInstances   : [
      't2.nano', 't2.micro', 't2.small', 't2.medium',
      'm3.medium', 'm1.medium', 't2.large', 'c3.large',
      'c4.large', 'c1.medium', 'm3.large', 'c3.xlarge',
      'c4.xlarge', 'm2.xlarge', 'm4.xlarge', 'm3.xlarge',
      'c3.2xlarge'
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
