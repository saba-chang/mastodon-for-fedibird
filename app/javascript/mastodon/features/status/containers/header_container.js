import { connect } from 'react-redux';
import { makeGetStatus } from '../../../selectors';
import Header from '../components/header';
import { injectIntl } from 'react-intl';
import { enableStatusReference  } from 'mastodon/initial_state';
import { List as ImmutableList } from 'immutable';

const makeMapStateToProps = () => {
  const getStatus = makeGetStatus();

  const mapStateToProps = (state, { statusId }) => {
    const status = getStatus(state, { id: statusId });
    const hasReference = !!(status && enableStatusReference && (status.get('status_references_count', 0) - (status.get('status_reference_ids', ImmutableList()).includes(status.get('quote_id')) > 0)));

    return {
      status,
      hasReference,
    };
  };

  return mapStateToProps;
};

export default injectIntl(connect(makeMapStateToProps)(Header));
