import Immutable from 'seamless-immutable'
import kd from 'kd'

const initialState = Immutable({})
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
    payload: Immutable(team),
    type: LOAD_TEAM
  };
}
