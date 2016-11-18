globals = require 'globals'

module.exports = parseTerraformOutput = (response) ->

  # An example of a valid stack template
  # ------------------------------------
  # title: "Default stack",
  # description: "Koding's default stack template for new users",
  # machines: [
  #   {
  #     "label" : "koding-vm-0",
  #     "provider" : "koding",
  #     "instanceType" : "t2.nano",
  #     "provisioners" : [
  #         "devrim/koding-base"
  #     ],
  #     "region" : "us-east-1",
  #     "source_ami" : "ami-a6926dce"
  #   }
  # ],

  out = { machines: [] }

  { machines } = response

  for machine, index in machines

    { label, provider } = machine

    machineBaseData = { label, provider }

    provider = globals.config.providers[provider]

    if attrMap = provider.attributeMapping
      (Object.keys attrMap).forEach (attribute) ->
        if attr = machine.attributes[attrMap[attribute]]
          machineBaseData[attribute] = attr

    out.machines.push machineBaseData

  console.info '[parseTerraformOutput]', out.machines

  return out.machines

