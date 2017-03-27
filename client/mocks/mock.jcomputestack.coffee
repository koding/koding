module.exports = {
  'watchers': {},
  'bongo_': {
    'constructorName': 'JComputeStack',
    'instanceId': '6a09ee09672e773b077b27a18385b702'
  },
  'title': 'My Stack',
  'originId': '569e54e73577d1b63864cc9f',
  'group': 'turunc-t-38',
  'baseStackId': '56aa08f0a6e74bce51cc885f',
  'stackRevision': 'a58e8b8f51dc70e5f7316dccacfb8a05eaad9b14',
  'machines': [
    {
      'id': 'kd-1217',
      'options': {},
      'data': {
        'watchers': {},
        'bongo_': {
          'constructorName': 'JMachine',
          'instanceId': 'cf27e4f8a927e3af48bc89297472a380'
        },
        'uid': 'utta2eac5ad0',
        'domain': 'utta2eac5ad0.turunc',
        'provider': 'aws',
        'label': 'mymachine_1',
        'slug': 'mymachine-1',
        'provisioners': [],
        'credential': '2f49083619c06a9f0a6039df83907748',
        'users': [
          {
            'id': '569e54e73577d1b63864cc9e',
            'sudo': true,
            'owner': true,
            'username': 'turunc'
          }
        ],
        'groups': [
          {
            'id': '56aa03f83a7307cd51c34047'
          }
        ],
        'createdAt': '2016-01-28T13:10:01.910Z',
        'status': {
          'state': 'NotInitialized',
          'modifiedAt': '2016-01-28T13:10:01.910Z'
        },
        'meta': {
          'type': 'aws',
          'region': 'us-east-1',
          'instance_type': 't2.nano',
          'storage_size': 8,
          'assignedLabel': 'mymachine_1'
        },
        'assignee': {
          'inProgress': false,
          'assignedAt': '2016-01-28T13:10:01.910Z'
        },
        'generatedFrom': {
          'templateId': '56aa08f0a6e74bce51cc885f',
          'revision': 'a58e8b8f51dc70e5f7316dccacfb8a05eaad9b14'
        },
        '_id': '56aa1329a6e74bce51cc886e'
      },
      '_e': {
        'newListener': [],
        'error': [
          null
        ],
        'ready': [
          null
        ]
      },
      '_maxListeners': 10,
      'label': 'mymachine_1',
      '_id': '56aa1329a6e74bce51cc886e',
      'provisioners': [],
      'provider': 'aws',
      'credential': '2f49083619c06a9f0a6039df83907748',
      'status': {
        'state': 'NotInitialized',
        'modifiedAt': '2016-01-28T13:10:01.910Z'
      },
      'uid': 'utta2eac5ad0',
      'domain': 'utta2eac5ad0.turunc',
      'slug': 'mymachine-1',
      'alwaysOn': false,
      'fs': {}
    }
  ],
  'config': {
    'requiredData': {
      'user': [
        'username'
      ],
      'group': [
        'slug'
      ]
    },
    'requiredProviders': [
      'aws',
      'koding'
    ],
    'verified': true,
    'groupStack': true
  },
  'meta': {
    'data': {
      'createdAt': '2016-01-28T13:10:01.889Z',
      'modifiedAt': '2016-01-28T13:10:01.889Z',
      'likes': 0
    },
    'createdAt': '2016-01-28T13:10:01.889Z',
    'modifiedAt': '2016-01-28T13:10:01.889Z',
    'likes': 0
  },
  'credentials': {
    'aws': [
      '2f49083619c06a9f0a6039df83907748'
    ]
  },
  'status': {
    'state': 'NotInitialized'
  },
  '_id': '56aa1329a6e74bce51cc886d',
  '_revisionStatus': {
    'error': null,
    'status': {
      'message': 'Base stack template is same',
      'code': 0
    }
  }
}
