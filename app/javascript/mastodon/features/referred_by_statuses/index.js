import React from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import ImmutablePropTypes from 'react-immutable-proptypes';
import LoadingIndicator from '../../components/loading_indicator';
import { fetchReferredByStatuses, expandReferredByStatuses } from '../../actions/interactions';
import Column from '../ui/components/column';
import Icon from 'mastodon/components/icon';
import ColumnHeader from '../../components/column_header';
import StatusList from '../../components/status_list';
import { defineMessages, injectIntl, FormattedMessage } from 'react-intl';
import ImmutablePureComponent from 'react-immutable-pure-component';
import ReactedHeaderContaier from '../reactioned/containers/header_container';
import { debounce } from 'lodash';
import { defaultColumnWidth } from 'mastodon/initial_state';
import { changeSetting } from '../../actions/settings';
import { changeColumnParams } from '../../actions/columns';

const messages = defineMessages({
  refresh: { id: 'refresh', defaultMessage: 'Refresh' },
  heading: { id: 'column.referred_by_statuses', defaultMessage: 'Referred by posts' },
});

const mapStateToProps = (state, { columnId, params }) => {
  const uuid = columnId;
  const columns = state.getIn(['settings', 'columns']);
  const index = columns.findIndex(c => c.get('uuid') === uuid);
  const columnWidth = (columnId && index >= 0) ? columns.get(index).getIn(['params', 'columnWidth']) : state.getIn(['settings', 'referred_by_statuses', 'columnWidth']);

  return {
    statusIds: state.getIn(['status_status_lists', 'referred_by', params.statusId, 'items']),
    isLoading: state.getIn(['status_status_lists', 'referred_by', params.statusId, 'isLoading'], true),
    hasMore: !!state.getIn(['status_status_lists', 'referred_by', params.statusId, 'next']),
    columnWidth: columnWidth ?? defaultColumnWidth,
  };
};

export default @connect(mapStateToProps)
@injectIntl
class ReferredByStatuses extends ImmutablePureComponent {

  static propTypes = {
    dispatch: PropTypes.func.isRequired,
    statusIds: ImmutablePropTypes.list,
    intl: PropTypes.object.isRequired,
    multiColumn: PropTypes.bool,
    columnWidth: PropTypes.string,
    hasMore: PropTypes.bool,
    isLoading: PropTypes.bool,
  };

  componentWillMount () {
    if (!this.props.statusIds) {
      this.props.dispatch(fetchReferredByStatuses(this.props.params.statusId));
    }
  }

  componentWillReceiveProps (nextProps) {
    if (nextProps.params.statusId !== this.props.params.statusId && nextProps.params.statusId) {
      this.props.dispatch(fetchEmojiReactions(nextProps.params.statusId));
    }
  }

  handleRefresh = () => {
    this.props.dispatch(fetchReferredByStatuses(this.props.params.statusId));
  }

  handleLoadMore = debounce(() => {
    this.props.dispatch(expandReferredByStatuses(this.props.params.statusId));
  }, 300, { leading: true })

  handleWidthChange = (value) => {
    const { columnId, dispatch } = this.props;

    if (columnId) {
      dispatch(changeColumnParams(columnId, 'columnWidth', value));
    } else {
      dispatch(changeSetting(['referred_by_statuses', 'columnWidth'], value));
    }
  }

  render () {
    const { intl, statusIds, multiColumn, hasMore, isLoading, columnWidth } = this.props;

    if (!statusIds) {
      return (
        <Column>
          <LoadingIndicator />
        </Column>
      );
    }

    const emptyMessage = <FormattedMessage id='empty_column.referred_by_statuses' defaultMessage="There are no referred by posts yet. When someone refers a post, it will appear here." />;

    return (
      <Column bindToDocument={!multiColumn} ref={this.setRef} label={intl.formatMessage(messages.heading)} columnWidth={columnWidth}>
        <ColumnHeader
          showBackButton
          multiColumn={multiColumn}
          columnWidth={columnWidth}
          onWidthChange={this.handleWidthChange}
          extraButton={(
            <button className='column-header__button' title={intl.formatMessage(messages.refresh)} aria-label={intl.formatMessage(messages.refresh)} onClick={this.handleRefresh}><Icon id='refresh' /></button>
          )}
        />

        <ReactedHeaderContaier statusId={this.props.params.statusId} />

        <StatusList
          statusIds={statusIds}
          scrollKey='referred-by-statuses'
          hasMore={hasMore}
          isLoading={isLoading}
          onLoadMore={this.handleLoadMore}
          emptyMessage={emptyMessage}
          bindToDocument={!multiColumn}
        />
      </Column>
    );
  }

}
