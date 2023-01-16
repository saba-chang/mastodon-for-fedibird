import React from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import ImmutablePropTypes from 'react-immutable-proptypes';
import LoadingIndicator from '../../components/loading_indicator';
import Column from '../ui/components/column';
import ColumnBackButtonSlim from '../../components/column_back_button_slim';
import { fetchLists } from '../../actions/lists';
import { defineMessages, injectIntl, FormattedMessage } from 'react-intl';
import ImmutablePureComponent from 'react-immutable-pure-component';
import ColumnSubheading from '../ui/components/column_subheading';
import NewListForm from './components/new_list_form';
import List from './components/list';
import { createSelector } from 'reselect';
import ScrollableList from '../../components/scrollable_list';
import { defaultColumnWidth } from 'mastodon/initial_state';

const messages = defineMessages({
  heading: { id: 'column.lists', defaultMessage: 'Lists' },
  subheading: { id: 'lists.subheading', defaultMessage: 'Your lists' },
});

const getOrderedLists = createSelector([state => state.get('lists')], lists => {
  if (!lists) {
    return lists;
  }

  return lists.toList().filter(item => !!item).sort((a, b) => a.get('title').localeCompare(b.get('title')));
});

const mapStateToProps = state => ({
  lists: getOrderedLists(state),
  columnWidth: defaultColumnWidth,
});

export default @connect(mapStateToProps)
@injectIntl
class Lists extends ImmutablePureComponent {

  static propTypes = {
    params: PropTypes.object.isRequired,
    dispatch: PropTypes.func.isRequired,
    lists: ImmutablePropTypes.list,
    intl: PropTypes.object.isRequired,
    multiColumn: PropTypes.bool,
    columnWidth: PropTypes.string,
  };

  componentWillMount () {
    this.props.dispatch(fetchLists());
  }

  render () {
    const { intl, lists, multiColumn, columnWidth } = this.props;

    if (!lists) {
      return (
        <Column>
          <LoadingIndicator />
        </Column>
      );
    }

    const emptyMessage = <FormattedMessage id='empty_column.lists' defaultMessage="You don't have any lists yet. When you create one, it will show up here." />;

    return (
      <Column bindToDocument={!multiColumn} icon='list-ul' heading={intl.formatMessage(messages.heading)} columnWidth={columnWidth}>
        <ColumnBackButtonSlim />

        <NewListForm />

        <ScrollableList
          scrollKey='lists'
          emptyMessage={emptyMessage}
          prepend={<ColumnSubheading text={intl.formatMessage(messages.subheading)} />}
          bindToDocument={!multiColumn}
          tabIndex='-1'
        >
          {lists.map(list =>
            <List key={list.get('id')} id={list.get('id')} text={list.get('title')} favourite={list.get('favourite')} animate />
          )}
        </ScrollableList>
      </Column>
    );
  }

}
