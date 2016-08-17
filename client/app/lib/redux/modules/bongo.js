import remote from 'app/remote'
import globals from 'globals'
import kd from 'kd'


export default function(){

  const bongo = remote.getInstance()
  const api = bongo.api

  api['JGroup'].one({ slug: globals.currentGroup.slug }, (err, group) =>

    console.log('group', group)
  )

  api['JComputeStack'].some({}, function(err, stacks = []){
    if(err)
      console.log('err', err)
    console.log('stacks', stacks)
  })

  api['JMachine'].some({}, (err, machines = []) =>
    console.log('machines', machines)
  )

  api['JInvitation'].some({ status: 'pending' }, {}, (err, invitations) =>
    console.log('pending invitations', invitations)
  )

  api['JStackTemplate'].some({ group: globals.currentGroup.slug }, {}, (err, templates) =>
    console.log('templates', templates)
  )

  const reducers= ['group', 'machine']

}
