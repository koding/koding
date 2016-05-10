module.exports = {
  'watchers': {},
  'bongo_': {
    'constructorName': 'JStackTemplate',
    'instanceId': '2a68ab44e407c1cca60aada3ea98cebb'
  },
  'machines': [
    {
      'label': 'example',
      'provider': 'aws',
      'region': 'us-east-1',
      'source_ami': 'ami-cf35f3a4',
      'instanceType': 't2.nano',
      'provisioners': []
    }
  ],
  'title': 'STACK 1',
  'description': '##### Readme text for this stack template\n\nYou can write down a readme text for new users.\nThis text will be shown when they want to use this stack.\nYou can use markdown with the readme content.\n\n',
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
    'groupStack': false,
    'verified': true
  },
  'accessLevel': 'group',
  'originId': '56e147d1aedf91e0087d67aa',
  'meta': {
    'data': {
      'createdAt': '2016-03-28T12:53:25.509Z',
      'modifiedAt': '2016-03-28T12:53:25.509Z',
      'likes': 0
    },
    'createdAt': '2016-03-28T12:53:25.509Z',
    'modifiedAt': '2016-03-28T12:53:25.509Z',
    'likes': 0
  },
  'group': 'turunc-team-hehe16',
  'template': {
    'content': '{&quot;provider&quot;:{&quot;aws&quot;:{&quot;access_key&quot;:&quot;${var.aws_access_key}&quot;,&quot;secret_key&quot;:&quot;${var.aws_secret_key}&quot;}},&quot;resource&quot;:{&quot;aws_instance&quot;:{&quot;example&quot;:{&quot;tags&quot;:{&quot;Name&quot;:&quot;${var.koding_user_username}-${var.koding_group_slug}&quot;},&quot;instance_type&quot;:&quot;t2.nano&quot;,&quot;ami&quot;:&quot;&quot;}}}}',
    'details': {},
    'rawContent': '# Here is your stack preview\n# You can make advanced changes like modifying your VM,\n# installing packages, and running shell commands.\n\nprovider:\n  aws:\n    access_key: &#39;${var.aws_access_key}&#39;\n    secret_key: &#39;${var.aws_secret_key}&#39;\nresource:\n  aws_instance:\n    example:\n      tags:\n        Name: &#39;${var.koding_user_username}-${var.koding_group_slug}&#39;\n      instance_type: t2.nano\n      ami: &#39;&#39;\n',
    'sum': '0857bea2903b56d1b530f120b8445a6074cb6da2'
  },
  'credentials': {
    'aws': [
      'ec7b8692888f0043e265d558d61818be'
    ]
  },
  '_id': '56f9294526efa37e25019dfc',
  'isDefault': false,
  'inUse': true
}
