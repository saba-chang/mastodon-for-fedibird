// @ts-check

import { connectStream } from '../stream';
import {
  updateTimeline,
  deleteFromTimelines,
  expireFromTimelines,
  expandHomeTimeline,
  connectTimeline,
  disconnectTimeline,
} from './timelines';
import { getHomeVisibilities } from 'mastodon/selectors';
import { updateNotifications, expandNotifications } from './notifications';
import { updateConversations } from './conversations';
import { updateEmojiReaction } from './interactions';
import {
  fetchAnnouncements,
  updateAnnouncements,
  updateReaction as updateAnnouncementsReaction,
  deleteAnnouncement,
} from './announcements';
import { fetchFilters } from './filters';
import { getLocale } from '../locales';

const { messages } = getLocale();

/**
 * @param {number} max
 * @return {number}
 */
const randomUpTo = max =>
  Math.floor(Math.random() * Math.floor(max));

/**
 * @param {string} timelineId
 * @param {string} channelName
 * @param {Object.<string, string>} params
 * @param {Object} options
 * @param {function(Function, Function): void} [options.fallback]
 * @param {function(object): boolean} [options.accept]
 * @return {function(): void}
 */
export const connectTimelineStream = (timelineId, channelName, params = {}, options = {}) =>
  connectStream(channelName, params, (dispatch, getState) => {
    const locale = getState().getIn(['meta', 'locale']);

    let pollingId;

    /**
     * @param {function(Function, Function, Function): void} fallback
     */
    const useFallback = fallback => {
      fallback(dispatch, getState, () => {
        pollingId = setTimeout(() => useFallback(fallback), 20000 + randomUpTo(20000));
      });
    };

    return {
      onConnect() {
        dispatch(connectTimeline(timelineId));

        if (pollingId) {
          clearTimeout(pollingId);
          pollingId = null;
        }
      },

      onDisconnect() {
        dispatch(disconnectTimeline(timelineId));

        if (options.fallback) {
          pollingId = setTimeout(() => useFallback(options.fallback), randomUpTo(40000));
        }
      },

      onReceive (data) {
        switch(data.event) {
        case 'update':
          dispatch(updateTimeline(timelineId, JSON.parse(data.payload), options.accept));
          break;
        case 'delete':
          dispatch(deleteFromTimelines(data.payload));
          break;
        case 'expire':
          dispatch(expireFromTimelines(data.payload));
          break;
        case 'notification':
          dispatch(updateNotifications(JSON.parse(data.payload), messages, locale));
          break;
        case 'conversation':
          dispatch(updateConversations(JSON.parse(data.payload)));
          break;
        case 'filters_changed':
          dispatch(fetchFilters());
          break;
        case 'emoji_reaction':
          dispatch(updateEmojiReaction(JSON.parse(data.payload)));
          break;
        case 'announcement':
          dispatch(updateAnnouncements(JSON.parse(data.payload)));
          break;
        case 'announcement.reaction':
          dispatch(updateAnnouncementsReaction(JSON.parse(data.payload)));
          break;
        case 'announcement.delete':
          dispatch(deleteAnnouncement(data.payload));
          break;
        }
      },
    };
  });

/**
 * @param {Function} dispatch
 * @param {function(): void} done
 */
const refreshHomeTimelineAndNotification = (dispatch, getState, done) => {
  const visibilities = getHomeVisibilities(getState());

  dispatch(expandHomeTimeline({ visibilities }, () =>
    dispatch(expandNotifications({}, () =>
      dispatch(fetchAnnouncements(done))))));
};

/**
 * @return {function(): void}
 */
export const connectUserStream = () =>
  connectTimelineStream('home', 'user', {}, { fallback: refreshHomeTimelineAndNotification });

/**
 * @param {Object} options
 * @param {boolean} [options.onlyMedia]
 * @return {function(): void}
 */
export const connectCommunityStream = ({ onlyMedia } = {}) =>
  connectTimelineStream(`community${onlyMedia ? ':media' : ''}`, `public:local${onlyMedia ? ':media' : ''}`);

/**
 * @param {string} domain
 * @param {Object} options
 * @param {boolean} [options.onlyMedia]
 * @return {function(): void}
 */
export const connectDomainStream = (domain, { onlyMedia } = {}) =>
  connectTimelineStream(`domain${onlyMedia ? ':media' : ''}:${domain}`, `public:domain${onlyMedia ? ':media' : ''}`, { domain: domain });

/**
 * @param {string} id
 * @param {Object} options
 * @param {boolean} [options.onlyMedia]
 * @param {string} [options.tagged]
 * @return {function(): void}
 */
export const connectGroupStream = (id, { onlyMedia, tagged } = {}) =>
  connectTimelineStream(`group:${id}${onlyMedia ? ':media' : ''}${tagged ? `:${tagged}` : ''}`, `group${onlyMedia ? ':media' : ''}`, { id: id, tagged: tagged });

/**
 * @param {Object} options
 * @param {boolean} [options.onlyRemote]
 * @param {boolean} [options.onlyMedia]
 * @return {function(): void}
 */
export const connectPublicStream = ({ onlyMedia, onlyRemote } = {}) =>
  connectTimelineStream(`public${onlyRemote ? ':remote' : ''}${onlyMedia ? ':media' : ''}`, `public${onlyRemote ? ':remote' : ''}${onlyMedia ? ':media' : ''}`);

/**
 * @param {string} columnId
 * @param {string} tagName
 * @param {boolean} onlyLocal
 * @param {function(object): boolean} accept
 * @return {function(): void}
 */
export const connectHashtagStream = (columnId, tagName, onlyLocal, accept) =>
  connectTimelineStream(`hashtag:${columnId}${onlyLocal ? ':local' : ''}`, `hashtag${onlyLocal ? ':local' : ''}`, { tag: tagName }, { accept });

/**
 * @return {function(): void}
 */
export const connectDirectStream = () =>
  connectTimelineStream('direct', 'direct');

/**
 * @param {string} listId
 * @return {function(): void}
 */
export const connectListStream = listId =>
  connectTimelineStream(`list:${listId}`, 'list', { list: listId });
