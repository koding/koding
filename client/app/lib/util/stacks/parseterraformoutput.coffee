module.exports = parseTerraformOutput = (response, supportedProviders) ->

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

  unless supportedProviders
    globals = require 'globals'
    supportedProviders = globals.config.providers

  out = { machines: [] }

  { machines } = response

  for machine, index in machines

    { label, provider } = machine

    machineBaseData = { label, provider }

    provider = supportedProviders[provider] ? {}

    if attrMap = provider.attributeMapping
      (Object.keys attrMap).forEach (attribute) ->
        if attr = machine.attributes[attrMap[attribute]]
          machineBaseData[attribute] = attr

    out.machines.push machineBaseData

  return out.machines
