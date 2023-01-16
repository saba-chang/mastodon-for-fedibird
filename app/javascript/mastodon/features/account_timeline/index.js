import React from 'react';
import { connect } from 'react-redux';
import ImmutablePropTypes from 'react-immutable-proptypes';
import PropTypes from 'prop-types';
import { fetchAccount } from '../../actions/accounts';
import { expandAccountFeaturedTimeline, expandAccountTimeline } from '../../actions/timelines';
import StatusList from '../../components/status_list';
import LoadingIndicator from '../../components/loading_indicator';
import Column from '../../components/column';
import ColumnHeader from '../../components/column_header';
import ColumnSettingsContainer from './containers/column_settings_container';
import HeaderContainer from './containers/header_container';
import ColumnBackButton from '../../components/column_back_button';
import { List as ImmutableList } from 'immutable';
import ImmutablePureComponent from 'react-immutable-pure-component';
import { defineMessages, injectIntl, FormattedMessage } from 'react-intl';
import { fetchAccountIdentityProofs } from '../../actions/identity_proofs';
import MissingIndicator from 'mastodon/components/missing_indicator';
import TimelineHint from 'mastodon/components/timeline_hint';
import { me, new_features_policy } from 'mastodon/initial_state';
import { connectTimeline, disconnectTimeline } from 'mastodon/actions/timelines';
import { fetchFeaturedTags } from '../../actions/featured_tags';

const emptyList = ImmutableList();

const messages = defineMessages({
  title: { id: 'column.account', defaultMessage: 'Account' },
});

const mapStateToProps = (state, { params: { accountId, tagged }, about, withReplies, posts }) => {
  posts = tagged ? false : posts;
  withReplies = tagged ? true : withReplies;
  const advancedMode = state.getIn(['settings', 'account', 'other', 'advancedMode'], new_features_policy === 'conservative' ? false : true);
  const hideFeaturedTags = state.getIn(['settings', 'account', 'other', 'hideFeaturedTags'], false);
  const withoutReblogs = advancedMode && state.getIn(['settings', 'account', 'other', 'withoutReblogs'], false);
  const showPostsInAbout = state.getIn(['settings', 'account', 'other', 'showPostsInAbout'], true);
  const hideRelation = state.getIn(['settings', 'account', 'other', 'hideRelation'], false);
  const path = `${accountId}${withReplies ? ':with_replies' : ''}${withoutReblogs ? ':without_reblogs' : ''}${tagged ? `:${tagged}` : ''}`;

  return {
    remote: !!(state.getIn(['accounts', accountId, 'acct']) !== state.getIn(['accounts', accountId, 'username'])),
    remoteUrl: state.getIn(['accounts', accountId, 'url']),
    isAccount: !!state.getIn(['accounts', accountId]),
    statusIds: advancedMode && about && !showPostsInAbout ? emptyList : state.getIn(['timelines', `account:${path}`, 'items'], emptyList),
    featuredStatusIds: (withReplies || posts) ? emptyList : state.getIn(['timelines', `account:${accountId}:pinned${tagged ? `:${tagged}` : ''}`, 'items'], emptyList),
    isLoading: state.getIn(['timelines', `account:${path}`, 'isLoading']),
    hasMore: state.getIn(['timelines', `account:${path}`, 'hasMore']),
    suspended: state.getIn(['accounts', accountId, 'suspended'], false),
    blockedBy: state.getIn(['relationships', accountId, 'blocked_by'], false),
    advancedMode,
    hideFeaturedTags,
    posts,
    withReplies,
    withoutReblogs,
    showPostsInAbout,
    hideRelation,
  };
};

const RemoteHint = ({ url }) => (
  <TimelineHint url={url} resource={<FormattedMessage id='timeline_hint.resources.statuses' defaultMessage='Older toots' />} />
);

RemoteHint.propTypes = {
  url: PropTypes.string.isRequired,
};

export default @connect(mapStateToProps)
@injectIntl
class AccountTimeline extends ImmutablePureComponent {

  static propTypes = {
    intl: PropTypes.object.isRequired,
    params: PropTypes.object.isRequired,
    dispatch: PropTypes.func.isRequired,
    statusIds: ImmutablePropTypes.list,
    featuredStatusIds: ImmutablePropTypes.list,
    isLoading: PropTypes.bool,
    hasMore: PropTypes.bool,
    about: PropTypes.bool,
    withReplies: PropTypes.bool,
    withoutReblogs: PropTypes.bool,
    posts: PropTypes.bool,
    advancedMode: PropTypes.bool,
    hideFeaturedTags: PropTypes.bool,
    hideRelation: PropTypes.bool,
    blockedBy: PropTypes.bool,
    isAccount: PropTypes.bool,
    suspended: PropTypes.bool,
    remote: PropTypes.bool,
    remoteUrl: PropTypes.string,
    multiColumn: PropTypes.bool,
  };

  static defaultProps = {
    about: false,
    withReplies: false,
    posts: false,
  };

  componentWillMount () {
    const { params: { accountId, tagged }, about, withReplies, posts, advancedMode, hideFeaturedTags, withoutReblogs, showPostsInAbout, dispatch } = this.props;

    dispatch(fetchAccount(accountId));
    dispatch(fetchAccountIdentityProofs(accountId));

    if (!withReplies && !posts) {
      dispatch(expandAccountFeaturedTimeline(accountId, { tagged }));
    }

    if (!about || !advancedMode || showPostsInAbout) {
      dispatch(expandAccountTimeline(accountId, { withReplies, tagged, withoutReblogs }));
    }

    if (tagged || !hideFeaturedTags) {
      dispatch(fetchFeaturedTags(accountId));
    }

    if (accountId === me) {
      dispatch(connectTimeline(`account:${me}`));
    }
  }

  componentWillReceiveProps (nextProps) {
    const { dispatch } = this.props;

    if ((nextProps.params.accountId !== this.props.params.accountId && nextProps.params.accountId)
      || (nextProps.params.tagged !== this.props.params.tagged)
      || nextProps.withReplies !== this.props.withReplies
      || nextProps.withoutReblogs !== this.props.withoutReblogs
      || nextProps.showPostsInAbout !== this.props.showPostsInAbout
    ) {
      dispatch(fetchAccount(nextProps.params.accountId));
      dispatch(fetchAccountIdentityProofs(nextProps.params.accountId));

      if (!nextProps.withReplies && !nextProps.posts) {
        dispatch(expandAccountFeaturedTimeline(nextProps.params.accountId, { tagged: nextProps.params.tagged }));
      }

      if (!nextProps.about || nextProps.showPostsInAbout) {
        dispatch(expandAccountTimeline(nextProps.params.accountId, { withReplies: nextProps.withReplies, tagged: nextProps.params.tagged, withoutReblogs: nextProps.withoutReblogs }));
      }

      if (nextProps.params.tagged || !nextProps.hideFeaturedTags) {
        dispatch(fetchFeaturedTags(nextProps.params.accountId));
      }
    }

    if ((!nextProps.about || !this.props.advancedMode) && nextProps.params.accountId === me && this.props.params.accountId !== me) {
      dispatch(connectTimeline(`account:${me}`));
    } else if (this.props.params.accountId === me && nextProps.params.accountId !== me) {
      dispatch(disconnectTimeline(`account:${me}`));
    }
  }

  componentWillUnmount () {
    const { dispatch, params: { accountId } } = this.props;

    if (accountId === me) {
      dispatch(disconnectTimeline(`account:${me}`));
    }
  }

  handleLoadMore = maxId => {
    this.props.dispatch(expandAccountTimeline(this.props.params.accountId, { maxId, withReplies: this.props.withReplies, tagged: this.props.params.tagged, withoutReblogs: this.props.withoutReblogs }));
  }

  handleHeaderClick = () => {
    this.column.scrollTop();
  }

  setRef = c => {
    this.column = c;
  }

  render () {
    const { intl, statusIds, featuredStatusIds, isLoading, hasMore, blockedBy, suspended, isAccount, multiColumn, remote, remoteUrl, about, withReplies, posts, advancedMode, hideFeaturedTags, showPostsInAbout, hideRelation } = this.props;

    if (!isAccount) {
      return (
        <Column>
          <ColumnBackButton multiColumn={multiColumn} />
          <MissingIndicator />
        </Column>
      );
    }

    if (!statusIds && isLoading) {
      return (
        <Column>
          <LoadingIndicator />
        </Column>
      );
    }

    let emptyMessage;

    if (suspended) {
      emptyMessage = <FormattedMessage id='empty_column.account_suspended' defaultMessage='Account suspended' />;
    } else if (blockedBy) {
      emptyMessage = <FormattedMessage id='empty_column.account_unavailable' defaultMessage='Profile unavailable' />;
    } else if (about && advancedMode && featuredStatusIds.isEmpty()) {
      emptyMessage = <FormattedMessage id='empty_column.pinned_unavailable' defaultMessage='Pinned posts unavailable' />;
    } else if (remote && statusIds.isEmpty()) {
      emptyMessage = <RemoteHint url={remoteUrl} />;
    } else {
      emptyMessage = <FormattedMessage id='empty_column.account_timeline' defaultMessage='No toots here!' />;
    }

    const remoteMessage = (!about && remote) ? <RemoteHint url={remoteUrl} /> : null;

    return (
      <Column bindToDocument={!multiColumn} ref={this.setRef} label={intl.formatMessage(messages.title)}>
        <ColumnHeader
          icon='user'
          active={false}
          title={intl.formatMessage(messages.title)}
          onClick={this.handleHeaderClick}
          pinned={false}
          multiColumn={multiColumn}
        >
          <ColumnSettingsContainer />
        </ColumnHeader>

        <StatusList
          prepend={<HeaderContainer accountId={this.props.params.accountId} tagged={this.props.params.tagged} hideProfile={withReplies || posts || !!this.props.params.tagged} hideRelation={!about && hideRelation} hideFeaturedTags={hideFeaturedTags} />}
          alwaysPrepend
          append={remoteMessage}
          scrollKey='account_timeline'
          statusIds={(suspended || blockedBy) ? emptyList : statusIds}
          featuredStatusIds={featuredStatusIds}
          isLoading={isLoading}
          hasMore={about && advancedMode && !showPostsInAbout ? null : hasMore}
          onLoadMore={about && advancedMode && !showPostsInAbout ? null : this.handleLoadMore}
          emptyMessage={emptyMessage}
          bindToDocument={!multiColumn}
          timelineId='account'
        />
      </Column>
    );
  }

}
