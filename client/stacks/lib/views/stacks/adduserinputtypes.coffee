# This function checks koding section of template,
# exracts user input types from there and adds them to userInput data
module.exports = addUserInputTypes = (template, requiredData) ->

  { userInput } = requiredData
  return  if not userInput or not template.koding

  types = template.koding.userInput ? {}
  requiredData.userInput = userInput.map (item) ->
    if type = types[item]
    then { name: item, type }
    else item
