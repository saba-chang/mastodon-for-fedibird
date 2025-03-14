import { createSelector } from 'reselect';
import { List as ImmutableList, Map as ImmutableMap, is } from 'immutable';
import { me, enable_limited_timeline } from '../initial_state';

const getAccountBase         = (state, id) => state.getIn(['accounts', id], null);
const getAccountCounters     = (state, id) => state.getIn(['accounts_counters', id], null);
const getAccountRelationship = (state, id) => state.getIn(['relationships', id], null);
const getAccountMoved        = (state, id) => state.getIn(['accounts', state.getIn(['accounts', id, 'moved'])]);

export const makeGetAccount = () => {
  return createSelector([getAccountBase, getAccountCounters, getAccountRelationship, getAccountMoved], (base, counters, relationship, moved) => {
    if (base === null) {
      return null;
    }

    return base.merge(counters).withMutations(map => {
      map.set('relationship', relationship);
      map.set('moved', moved);
    });
  });
};

const toServerSideType = columnType => {
  switch (columnType) {
  case 'home':
  case 'notifications':
  case 'public':
  case 'thread':
  case 'account':
    return columnType;
  default:
    if (columnType.indexOf('list:') > -1) {
      return 'home';
    } else {
      return 'public'; // community, account, hashtag
    }
  }
};

const escapeRegExp = string =>
  string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'); // $& means the whole matched string

const regexFromFilters = filters => {
  if (filters.size === 0) {
    return null;
  }

  return new RegExp(filters.map(filter => {
    let expr = escapeRegExp(filter.get('phrase'));

    if (filter.get('whole_word')) {
      if (/^[\w]/.test(expr)) {
        expr = `\\b${expr}`;
      }

      if (/[\w]$/.test(expr)) {
        expr = `${expr}\\b`;
      }
    }

    return expr;
  }).join('|'), 'i');
};

// Memoize the filter regexps for each valid server contextType
const makeGetFiltersRegex = () => {
  let memo = {};

  return (state, { contextType }) => {
    if (!contextType) return ImmutableList();

    const serverSideType = toServerSideType(contextType);
    const filters = state.get('filters', ImmutableList()).filter(filter => filter.get('context').includes(serverSideType) && (filter.get('expires_at') === null || Date.parse(filter.get('expires_at')) > (new Date())));

    if (!memo[serverSideType] || !is(memo[serverSideType].filters, filters)) {
      const dropRegex = regexFromFilters(filters.filter(filter => filter.get('irreversible')));
      const regex = regexFromFilters(filters);
      memo[serverSideType] = { filters: filters, results: [dropRegex, regex] };
    }
    return memo[serverSideType].results;
  };
};

export const getFiltersRegex = makeGetFiltersRegex();

export const makeGetStatus = () => {
  return createSelector(
    [
      (state, { id }) => state.getIn(['statuses', id]),
      (state, { id }) => state.getIn(['statuses', state.getIn(['statuses', id, 'reblog'])]),
      (state, { id }) => state.getIn(['statuses', state.getIn(['statuses', id, 'quote_id'])]),
      (state, { id }) => state.getIn(['accounts', state.getIn(['statuses', id, 'account'])]),
      (state, { id }) => state.getIn(['accounts', state.getIn(['statuses', state.getIn(['statuses', id, 'reblog']), 'account'])]),
      (state, { id }) => state.getIn(['accounts', state.getIn(['statuses', state.getIn(['statuses', id, 'quote_id']), 'account'])]),
      (state, { id }) => state.getIn(['accounts', state.getIn(['statuses', state.getIn(['statuses', id, 'reblog']), 'quote', 'account'])]),
      (state, { id }) => state.getIn(['relationships', state.getIn(['statuses', id, 'account'])]),
      (state, { id }) => state.getIn(['relationships', state.getIn(['statuses', state.getIn(['statuses', id, 'reblog']), 'account'])]),
      (state, { id }) => state.getIn(['relationships', state.getIn(['statuses', state.getIn(['statuses', id, 'quote_id']), 'account'])]),
      (state, { id }) => state.getIn(['relationships', state.getIn(['statuses', state.getIn(['statuses', id, 'reblog']), 'quote', 'account'])]),
      (state, { id }) => state.getIn(['accounts', state.getIn(['accounts', state.getIn(['statuses', id, 'account']), 'moved'])]),
      (state, { id }) => state.getIn(['accounts', state.getIn(['accounts', state.getIn(['statuses', state.getIn(['statuses', id, 'reblog']), 'account']), 'moved'])]),
      (state, { id }) => state.getIn(['accounts', state.getIn(['accounts', state.getIn(['statuses', state.getIn(['statuses', id, 'quote_id']), 'account']), 'moved'])]),
      (state, { id }) => state.getIn(['accounts', state.getIn(['accounts', state.getIn(['statuses', state.getIn(['statuses', id, 'reblog']), 'quote', 'account']), 'moved'])]),
      getFiltersRegex,
    ],

    (statusBase, statusReblog, statusQuote, accountBase, accountReblog, accountQuote, accountReblogQuote, relationship, reblogRelationship, quoteRelationship, reblogQuoteRelationship, moved, reblogMoved, quoteMoved, reblogQuoteMoved, filtersRegex) => {
      if (!statusBase) {
        return null;
      }

      accountBase = accountBase.withMutations(map => {
        map.set('relationship', relationship);
        map.set('moved', moved);
      });

      if (statusReblog) {
        accountReblog = accountReblog.withMutations(map => {
          map.set('relationship', reblogRelationship);
          map.set('moved', reblogMoved);
        });
        statusReblog = statusReblog.set('account', accountReblog);
      } else {
        statusReblog = null;
      }

      if (statusQuote) {
        accountQuote = accountQuote.withMutations(map => {
          map.set('relationship', quoteRelationship);
          map.set('moved', quoteMoved);
        });
        statusQuote = statusQuote.set('account', accountQuote);
      } else {
        statusQuote = null;
      }

      if (statusReblog && accountReblogQuote) {
        accountReblogQuote = accountReblog.withMutations(map => {
          map.set('relationship', reblogQuoteRelationship);
          map.set('moved', reblogQuoteMoved);
        });
        statusReblog = statusReblog.setIn(['quote', 'account'], accountReblogQuote);
      }

      const dropRegex = (accountReblog || accountBase).get('id') !== me && filtersRegex[0];
      if (dropRegex && dropRegex.test(statusBase.get('reblog') ? statusReblog.get('search_index') : statusBase.get('search_index'))) {
        return null;
      }

      const regex     = (accountReblog || accountBase).get('id') !== me && filtersRegex[1];
      const filtered  = regex && regex.test(statusBase.get('reblog') ? statusReblog.get('search_index') : statusBase.get('search_index'));

      return statusBase.withMutations(map => {
        map.set('reblog', statusReblog);
        map.set('quote', statusQuote);
        map.set('account', accountBase);
        map.set('filtered', filtered);
      });
    },
  );
};

export const makeGetPictureInPicture = () => {
  return createSelector([
    (state, { id }) => state.get('picture_in_picture').statusId === id,
    (state) => state.getIn(['meta', 'layout']) !== 'mobile',
  ], (inUse, available) => ImmutableMap({
    inUse: inUse && available,
    available,
  }));
};

const getAlertsBase = state => state.get('alerts');

export const getAlerts = createSelector([getAlertsBase], (base) => {
  let arr = [];

  base.forEach(item => {
    arr.push({
      message: item.get('message'),
      message_values: item.get('message_values'),
      title: item.get('title'),
      key: item.get('key'),
      dismissAfter: 5000,
      barStyle: {
        zIndex: 200,
      },
    });
  });

  return arr;
});

export const makeGetNotification = () => {
  return createSelector([
    (_, base)             => base,
    (state, _, accountId) => state.getIn(['accounts', accountId]),
  ], (base, account) => {
    return base.set('account', account);
  });
};

export const getAccountGallery = createSelector([
  (state, id) => state.getIn(['timelines', `account:${id}:media`, 'items'], ImmutableList()),
  state       => state.get('statuses'),
  (state, id) => state.getIn(['accounts', id]),
], (statusIds, statuses, account) => {
  let medias = ImmutableList();

  statusIds.forEach(statusId => {
    const status = statuses.get(statusId);
    medias = medias.concat(status.get('media_attachments').map(media => media.set('status', status).set('account', account)));
  });

  return medias;
});

export const getHomeVisibilities = createSelector(
  state => state.getIn(['settings', 'home', 'shows']),
  shows => {
    return enable_limited_timeline ? (
      ['public', 'unlisted']
      .concat(shows.get('private') ? ['private'] : [])
      .concat(shows.get('limited') ? ['limited'] : [])
      .concat(shows.get('direct')  ? ['direct']  : [])
    ) : [];
});

export const getLimitedVisibilities = createSelector(
  state => state.getIn(['settings', 'limited', 'shows']),
  shows => {
    return enable_limited_timeline ? (
      []
      .concat(shows.get('private') ? ['private'] : [])
      .concat(shows.get('limited') ? ['limited'] : [])
      .concat(shows.get('direct')  ? ['direct']  : [])
    ) : [];
});
