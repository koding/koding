import Immutable from 'seamless-immutable'
import kd from 'kd'

const initialState = Immutable({})
const LOAD_TEAM = 'app/team/LOAD_TEAM'

export default function reducer(state = initialState, action = {}){
  switch(action.type){
    case LOAD_TEAM:
      const prototype = Object.getPrototypeOf(action.payload)
      return Immutable(action.payload, { prototype: prototype })

    default:
      return state;
  }
}

export function loadTeam() {

  const team = kd.singletons.groupsController.getCurrentGroup()

  return {
    payload: team,
    type: LOAD_TEAM
  };
}
