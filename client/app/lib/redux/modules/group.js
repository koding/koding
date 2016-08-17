import Immutable from 'seamless-immutable'
import kd from 'kd'
import remote from 'app/remote'
import globals from 'globals'
const bongo = remote.getInstance()
const api = bongo.api

const initialState = Immutable({})
const JGroup = 'app/redux/JGroup'

const LOAD_GROUP = 'app/redux/LOAD_GROUP'
const LOAD_GROUP_FAIL = 'app/redux/LOAD_GROUP_FAIL'
const LOAD_GROUP_SUCCESS = 'app/redux/LOAD_GROUP_SUCCESS'

export default function reducer(state = initialState, action = {}){

  switch(action.type){
    case LOAD_GROUP:
      console.log('fetching group...')
      return state;

    case LOAD_GROUP_FAIL:
      console.log('err occured while fetching...', action.err)
      return state;

    case LOAD_GROUP_SUCCESS:
      const group = action.group
      console.log('fetch success ', group)
      const prototype = Object.getPrototypeOf(group)
      return Immutable(action.group, { prototype: prototype })

    default:
      return state;
  }
}


export function loadGroup(){

  return (dispatch) => {
    const slug = globals.currentGroup.slug

    dispatch({ type: LOAD_GROUP })

    api['JGroup'].one({ slug }, (err, group) => {
      if(err)
        return dispatch({ type: LOAD_GROUP_FAIL, err })
      dispatch({ type: LOAD_GROUP_SUCCESS, group })
    })
  }
}