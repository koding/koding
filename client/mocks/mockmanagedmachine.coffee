{ assign } = require 'lodash'

username = require('app/util/nick')()
{ _id: userId } = require('app/util/whoami')()
{ _id: groupId } = require('app/util/getGroup')()

label = 'test-machine'
domain = [label, username].join '.'

module.exports = mockManagedMachine = -> {
  "isApproved": true,
  "isTestMachine": true,
  "_conf": {
    "domain": domain,
    "meta": {
      "alwaysOn": false,
      "managedProvider": "UnknownProvider",
      "storage_size": 0,
      "type": "managed"
    },
    "users": [
      {
        "id": userId,
        "sudo": true,
        "owner": true,
        "username": username
      }
    ],
    "slug": label,
    "ipAddress": domain,
    "assignee": {
      "inProgress": false,
      "assignedAt": "2016-10-12T07:13:23.305Z"
    },
    "uid": label,
    "provisioners": [],
    "provider": "managed",
    "status": {
      "state": "Running"
    },
    "groups": [
      {
        "id": groupId
      }
    ],
    "label": label,
    "credential": username,
    "generatedFrom": null,
    "queryString": "///////98a941fb-62aa-428e-9d2d-5eabfc7fedc7",
    "_id": label,
    "createdAt": "2016-10-12T07:13:23.305Z"
  },
  "domain": domain,
  "meta": {
    "alwaysOn": false,
    "managedProvider": "UnknownProvider",
    "storage_size": 0,
    "type": "managed"
  },
  "hasOldOwner": false,
  "users": [
    {
      "id": userId,
      "sudo": true,
      "owner": true,
      "username": username
    }
  ],
  "slug": label,
  "ipAddress": domain,
  "assignee": {
    "inProgress": false,
    "assignedAt": "2016-10-12T07:13:23.305Z"
  },
  "isShared": false,
  "uid": label,
  "provisioners": [],
  "provider": "managed",
  "status": {
    "state": "Running"
  },
  "owner": username,
  "groups": [
    {
      "id": groupId
    }
  ],
  "newListener": false,
  "label": label,
  "bongo_": {
    "constructorName": "JMachine",
    "instanceId": label,
  },
  "credential": username,
  "watchers": {},
  "queryString": "///////98a941fb-62aa-428e-9d2d-5eabfc7fedc7",
  "_id": label,
  "percentage": 100,
  "type": "own",
  "createdAt": "2016-10-12T07:13:23.305Z"
}
