konstraints = require 'konstraints'

rules = [

   { $typeof : 'object' }
   { $keys   : ['provider', 'resource'] }

   { 'provider'  : [
       { $typeof : 'object' }
       { $keys   : ['aws'] }
     ]
   }

   { 'provider.aws' : [
       { $typeof    : 'object' }
       { $length    : 2 }
     ]
   }

   { 'provider.aws.access_key' : { $eq: '${var.aws_access_key}' } }
   { 'provider.aws.secret_key' : { $eq: '${var.aws_secret_key}' } }

   { 'resource' : [
       { $typeof : 'object' }
       { $keys   : ['aws_instance'] }
     ]
   }

   { 'resource.aws_instance': [
       { $typeof : 'object' }
       { $length : { $lte: 1 } }
     ]
   }

   { 'resource.aws_instance.*': [

       { $keys : [
           'tags', 'instance_type', 'ami', 'user_data', 'root_block_device'
         ]
       }

       { 'ami'       : { $eq: '' } }
       { 'tags.Name' : {
          $eq : "${var.koding_user_username}-${var.koding_group_slug}"
         }
       }

       { 'instance_type': { $typeof: 'string' } }
       { 'instance_type': { $in: ['t2.micro', 't2.medium'] } }

       { 'root_block_device.volume_size?': { $typeof: 'number' } }
       { 'root_block_device.volume_size?': { $lte: 30 } }
       { 'root_block_device.volume_size?': { $gt: 3 } }

     ]
   }

]

module.exports = constraintChecker = (template) ->

  if typeof template is 'string'
    try
      template = JSON.parse template
    catch
      return { message: 'Template is not valid JSON' }

  { passed, results } = konstraints template, rules, log: yes

  return results.last[1]  unless passed
  return null
