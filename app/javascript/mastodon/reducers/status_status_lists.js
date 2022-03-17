import {
  REFERRED_BY_STATUSES_FETCH_REQUEST,
  REFERRED_BY_STATUSES_FETCH_SUCCESS,
  REFERRED_BY_STATUSES_FETCH_FAIL,
  REFERRED_BY_STATUSES_EXPAND_REQUEST,
  REFERRED_BY_STATUSES_EXPAND_SUCCESS,
  REFERRED_BY_STATUSES_EXPAND_FAIL,
} from '../actions/interactions';
import { Map as ImmutableMap, List as ImmutableList } from 'immutable';

const initialState = ImmutableMap({
  referred_by: ImmutableMap(),
});

const normalizeList = (state, path, statuses, next) => {
  return state.setIn(path, ImmutableMap({
    next,
    items: ImmutableList(statuses.map(item => item.id)),
    isLoading: false,
  }));
};

const appendToList = (state, path, statuses, next) => {
  return state.updateIn(path, map => {
    return map.set('next', next).set('isLoading', false).update('items', list => list.concat(statuses.map(item => item.id)));
  });
};

export default function userLists(state = initialState, action) {
  switch(action.type) {
  case REFERRED_BY_STATUSES_FETCH_SUCCESS:
    return normalizeList(state, ['referred_by', action.id], action.statuses, action.next);
  case REFERRED_BY_STATUSES_EXPAND_SUCCESS:
    return appendToList(state, ['referred_by', action.id], action.statuses, action.next);
  case REFERRED_BY_STATUSES_FETCH_REQUEST:
  case REFERRED_BY_STATUSES_EXPAND_REQUEST:
    return state.setIn(['referred_by', action.id, 'isLoading'], true);
  case REFERRED_BY_STATUSES_FETCH_FAIL:
  case REFERRED_BY_STATUSES_EXPAND_FAIL:
    return state.setIn(['referred_by', action.id, 'isLoading'], false);
  default:
    return state;
  }
};
