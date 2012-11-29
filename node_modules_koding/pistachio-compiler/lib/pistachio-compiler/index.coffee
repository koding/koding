falafel = require 'falafel'
{argv} = require 'optimist'

compile = require './compile'

compileAll =(source)->
  falafel source, (node)->
    node.update compile node.source()  if node.type is 'Literal'

isMagicProperty =(node, magicWord)->
  node.type is 'Property' and node.key.name is magicWord

isMagicMember =(node, magicWord)->
  node.type is 'AssignmentExpression' and\
  node.left.type is 'MemberExpression' and\
  node.left.property.name is magicWord

isMagicIdentifier =(node, magicWord)->
  node.type is 'AssignmentExpression' and\
  node.left.type is 'Identifier' and\
  node.left.name is magicWord

module.exports =(src, magicWord="pistachio")->
  falafel src, (node)->
    if isMagicProperty(node, magicWord) or\
       isMagicMember(node, magicWord) or\
       isMagicIdentifier(node, magicWord)
      node.update compileAll node.source()