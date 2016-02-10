# This function checks koding section of template,
# exracts user input types from there and adds them to userInput data
module.exports = addUserInputTypes = (template, requiredData) ->

  { userInput } = requiredData
  return  unless userInput and template.koding

  types = template.koding.userInput
  requiredData.userInput = userInput.map (item) ->
    type = types[item]
    if type then { name: item, type } else item
