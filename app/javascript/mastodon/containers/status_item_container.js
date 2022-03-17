import { connect } from 'react-redux';
import StatusItem from '../components/status_item';
import { makeGetStatus } from '../selectors';
import {
  removeReference,
} from '../actions/compose';
import { openModal } from '../actions/modal';
import { unselectReferenceModal } from '../initial_state';

import { injectIntl, defineMessages } from 'react-intl';

import { createSelector } from 'reselect';
import { Map as ImmutableMap } from 'immutable';

const messages = defineMessages({
  unselectMessage: { id: 'confirmations.unselect.message', defaultMessage: 'Are you sure you want to unselect a reference?' },
  unselectConfirm: { id: 'confirmations.unselect.confirm', defaultMessage: 'Unselect' },
});

const makeMapStateToProps = () => {
  const getStatus = makeGetStatus();
  const customEmojiMap = createSelector([state => state.get('custom_emojis')], items => items.reduce((map, emoji) => map.set(emoji.get('shortcode'), emoji), ImmutableMap()));

  const mapStateToProps = (state, props) => {
    const status = getStatus(state, props);

    return {
      status,
      emojiMap: customEmojiMap(state),
    }
  };

  return mapStateToProps;
};

const mapDispatchToProps = (dispatch, { intl }) => ({

  onUnselectReference (id, e) {
    if (!unselectReferenceModal || e && e.shiftKey) {
      dispatch(removeReference(id));
    } else {
      dispatch(openModal('CONFIRM', {
        message: intl.formatMessage(messages.unselectMessage),
        confirm: intl.formatMessage(messages.unselectConfirm),
        onConfirm: () => dispatch(removeReference(id)),
      }));
    }
  },

});

export default injectIntl(connect(makeMapStateToProps, mapDispatchToProps)(StatusItem));
