sys = require('sys')
xml = require('o3-xml')
{Util} = require('./util')

class XmlParser
  TEXT_NODE = 3

  @parse: (text) ->
    new XmlParser().parse(text)

  convertNodeToObject: (node) ->
    object = {}
    obj = {}
    for child in node.childNodes
      if child.nodeType isnt TEXT_NODE
        name = Util.toCamelCase(child.nodeName)
        if child.childNodes.length is 1 && child.childNodes[0].nodeType is TEXT_NODE
          if child.attributes.length is 1 && child.attributes[0].name is 'type' && child.attributes[0].value is 'boolean'
            obj[name] = if child.childNodes[0].nodeValue is 'true' then true else false
          else
            obj[name] = child.childNodes[0].nodeValue
        else if child.childNodes.length is 0 && child.attributes.length is 1 && child.attributes[0].name is 'nil'
          obj[name] = null
        else if child.childNodes.length is 0 && child.attributes.length is 1 && child.attributes[0].name is 'type' && child.attributes[0].value is 'array'
          obj[name] = []
        else if child.attributes.length is 1 && child.attributes[0].name is 'type' && child.attributes[0].value is 'array'
          obj[name] = (@convertNodeToObject(arrayItem)[Util.toCamelCase(arrayItem.nodeName)] for arrayItem in child.childNodes when arrayItem.nodeType isnt TEXT_NODE)
        else
          obj[name] = @convertNodeToObject(child)[Util.toCamelCase(child.nodeName)]
    object[Util.toCamelCase(node.nodeName)] = obj
    object

  parse: (body) ->
    doc = xml.parseFromString(body)
    @convertNodeToObject(doc.documentElement)

exports.XmlParser = XmlParser
