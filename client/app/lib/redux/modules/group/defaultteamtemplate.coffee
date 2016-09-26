{ makeNamespace, expandActionType,
  normalize, defineSchema } = require 'app/redux/helper'

withNamespace = makeNamespace 'koding', 'group', 'defaultteamttemplate'

LOAD = expandActionType withNamespace 'LOAD'
CREATE = expandActionType withNamespace 'CREATE'
REMOVE = expandActionType withNamespace 'REMOVE'

reducer = (state = null, action) ->

  switch action.type

    when LOAD.SUCCESS, CREATE.SUCCESS
      return state


modify = (group, templateId) ->

  return {
    type: 'MODIFY'
    promise: -> new Promise (resolve, reject) ->
      group.modify { stackTemplates: [templateId] }, (err) ->
        return resolve()  unless err

        return reject()
  }

sendNotification = (group, templateId) ->

  return {
    type: 'WARNTEAMMEMBER'
    promise: -> new Promise (resolve, reject) ->
      group.sendNotification 'StackTemplateChanged', templateId
  }


module.exports = _.assign reducer, {
  namespace: withNamespace()
  reducer
  modify, sendNotification
  LOAD, CREATE, REMOVE
}