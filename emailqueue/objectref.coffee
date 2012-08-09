
Inflector = require 'inflector'

module.exports =
  isObjectRef:(obj)-> obj?.constructorName? and obj.id?
  populate:(db, objRef, callback)->
    collectionName = "#{Inflector(objRef.constructorName).pluralize().decapitalize()}"
    db.collection(collectionName).findOne _id: objRef.id, (err, object)->
      if err
        callback err
      else
        callback null, object