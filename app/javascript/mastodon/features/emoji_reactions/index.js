import React from 'react';
import { connect } from 'react-redux';
import ImmutablePureComponent from 'react-immutable-pure-component';
import PropTypes from 'prop-types';
import ImmutablePropTypes from 'react-immutable-proptypes';
import LoadingIndicator from '../../components/loading_indicator';
import { fetchEmojiReactions, expandEmojiReactions } from '../../actions/interactions';
import { defineMessages, injectIntl, FormattedMessage } from 'react-intl';
import AccountContainer from '../../containers/account_container';
import Column from '../ui/components/column';
import ScrollableList from '../../components/scrollable_list';
import Icon from 'mastodon/components/icon';
import ColumnHeader from '../../components/column_header';
import Emoji from '../../components/emoji';
import { createSelector } from 'reselect';
import { Map as ImmutableMap } from 'immutable';
import ReactedHeaderContaier from '../reactioned/containers/header_container';
import { debounce } from 'lodash';

const messages = defineMessages({
  refresh: { id: 'refresh', defaultMessage: 'Refresh' },
});

const customEmojiMap = createSelector([state => state.get('custom_emojis')], items => items.reduce((map, emoji) => map.set(emoji.get('shortcode'), emoji), ImmutableMap()));

const mapStateToProps = (state, props) => ({
  emojiReactions: state.getIn(['user_lists', 'emoji_reactioned_by', props.params.statusId, 'items']),
  isLoading: state.getIn(['user_lists', 'emoji_reactioned_by', props.params.statusId, 'isLoading'], true),
  hasMore: !!state.getIn(['user_lists', 'emoji_reactioned_by', props.params.statusId, 'next']),
  emojiMap: customEmojiMap(state),
});

class Reaction extends ImmutablePureComponent {

  static propTypes = {
    emojiReaction: ImmutablePropTypes.map.isRequired,
    emojiMap: ImmutablePropTypes.map.isRequired,
  };

  state = {
    hovered: false,
  };

  handleMouseEnter = () => this.setState({ hovered: true })

  handleMouseLeave = () => this.setState({ hovered: false })

  render () {
    const { emojiReaction, emojiMap } = this.props;

    return (
      <div className='account__emoji_reaction' onMouseEnter={this.handleMouseEnter} onMouseLeave={this.handleMouseLeave}>
        <Emoji hovered={this.state.hovered} emoji={emojiReaction.get('name')} emojiMap={emojiMap} url={emojiReaction.get('url')} static_url={emojiReaction.get('static_url')} />
      </div>
    );
  };
}

export default @connect(mapStateToProps)
@injectIntl
class EmojiReactions extends ImmutablePureComponent {

  static propTypes = {
    params: PropTypes.object.isRequired,
    dispatch: PropTypes.func.isRequired,
    emojiReactions: ImmutablePropTypes.list,
    multiColumn: PropTypes.bool,
    emojiMap: ImmutablePropTypes.map.isRequired,
    intl: PropTypes.object.isRequired,
    hasMore: PropTypes.bool,
    isLoading: PropTypes.bool,
  };

  componentWillMount () {
    if (!this.props.emojiReactions) {
      this.props.dispatch(fetchEmojiReactions(this.props.params.statusId));
    }
  }

  componentWillReceiveProps (nextProps) {
    if (nextProps.params.statusId !== this.props.params.statusId && nextProps.params.statusId) {
      this.props.dispatch(fetchEmojiReactions(nextProps.params.statusId));
    }
  }

  handleRefresh = () => {
    this.props.dispatch(fetchEmojiReactions(this.props.params.statusId));
  }

  handleLoadMore = debounce(() => {
    this.props.dispatch(expandEmojiReactions(this.props.params.statusId));
  }, 300, { leading: true })

  render () {
    const { intl, emojiReactions, multiColumn, emojiMap, hasMore, isLoading } = this.props;

    if (!emojiReactions) {
      return (
        <Column>
          <LoadingIndicator />
        </Column>
      );
    }

    const emptyMessage = <FormattedMessage id='empty_column.emoji_reactions' defaultMessage='No one has reactioned this post yet. When someone does, they will show up here.' />;

    return (
      <Column bindToDocument={!multiColumn}>
        <ColumnHeader
          showBackButton
          multiColumn={multiColumn}
          extraButton={(
            <button className='column-header__button' title={intl.formatMessage(messages.refresh)} aria-label={intl.formatMessage(messages.refresh)} onClick={this.handleRefresh}><Icon id='refresh' /></button>
          )}
        />

        <ReactedHeaderContaier statusId={this.props.params.statusId} />

        <ScrollableList
          scrollKey='emoji_reactions'
          hasMore={hasMore}
          isLoading={isLoading}
          onLoadMore={this.handleLoadMore}
          emptyMessage={emptyMessage}
          bindToDocument={!multiColumn}
        >
          {emojiReactions.map(emojiReaction =>
            <AccountContainer key={emojiReaction.get('account')+emojiReaction.get('name')} id={emojiReaction.get('account')} withNote={false} append={<Reaction emojiReaction={emojiReaction} emojiMap={emojiMap} />} />,
          )}
        </ScrollableList>
      </Column>
    );
  }

}
