import immutable from 'immutable'
import toImmutable from 'app/util/toImmutable'
import kd from 'kd'

const initialState = immutable.Map()
const LOAD_TEAM = 'app/team/LOAD_TEAM'

export default function reducer(state = initialState, action = {}){
  switch(action.type){
    case LOAD_TEAM:
      return { team: action.payload };

    default:
      return state;
  }
}

export function loadTeam(){

  const team = kd.singletons.groupsController.getCurrentGroup()

  return {
    payload: toImmutable(team),
    type: LOAD_TEAM
  };
}
