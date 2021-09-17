import React from 'react';
import { connect } from 'react-redux';
import ImmutablePureComponent from 'react-immutable-pure-component';
import PropTypes from 'prop-types';
import ImmutablePropTypes from 'react-immutable-proptypes';
import LoadingIndicator from '../../components/loading_indicator';
import { fetchMentions, expandMentions } from '../../actions/interactions';
import { injectIntl, FormattedMessage } from 'react-intl';
import AccountContainer from '../../containers/account_container';
import Column from '../ui/components/column';
import ScrollableList from '../../components/scrollable_list';
import ColumnHeader from '../../components/column_header';
import { debounce } from 'lodash';

const mapStateToProps = (state, props) => ({
  accountIds: state.getIn(['user_lists', 'mentioned_by', props.params.statusId, 'items']),
  isLoading: state.getIn(['user_lists', 'mentioned_by', props.params.statusId, 'isLoading'], true),
  hasMore: !!state.getIn(['user_lists', 'mentioned_by', props.params.statusId, 'next']),
});

export default @connect(mapStateToProps)
@injectIntl
class Mentions extends ImmutablePureComponent {

  static propTypes = {
    params: PropTypes.object.isRequired,
    dispatch: PropTypes.func.isRequired,
    accountIds: ImmutablePropTypes.list,
    multiColumn: PropTypes.bool,
    intl: PropTypes.object.isRequired,
    hasMore: PropTypes.bool,
    isLoading: PropTypes.bool,
  };

  componentWillMount () {
    if (!this.props.accountIds) {
      this.props.dispatch(fetchMentions(this.props.params.statusId));
    }
  }

  componentWillReceiveProps (nextProps) {
    if (nextProps.params.statusId !== this.props.params.statusId && nextProps.params.statusId) {
      this.props.dispatch(fetchMentions(nextProps.params.statusId));
    }
  }

  handleLoadMore = debounce(() => {
    this.props.dispatch(expandMentions(this.props.params.statusId));
  }, 300, { leading: true })

  render () {
    const { accountIds, multiColumn, hasMore, isLoading } = this.props;

    if (!accountIds) {
      return (
        <Column>
          <LoadingIndicator />
        </Column>
      );
    }

    const emptyMessage = <FormattedMessage id='empty_column.mentions' defaultMessage='No one has mentioned this toot.' />;

    return (
      <Column bindToDocument={!multiColumn}>
        <ColumnHeader
          showBackButton
          multiColumn={multiColumn}
        />

        <ScrollableList
          scrollKey='mentions'
          hasMore={hasMore}
          isLoading={isLoading}
          onLoadMore={this.handleLoadMore}
          emptyMessage={emptyMessage}
          bindToDocument={!multiColumn}
        >
          {accountIds.map(id =>
            <AccountContainer key={id} id={id} withNote={false} />,
          )}
        </ScrollableList>
      </Column>
    );
  }

}
