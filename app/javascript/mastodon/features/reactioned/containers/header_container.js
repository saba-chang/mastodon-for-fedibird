import { connect } from 'react-redux';
import { makeGetStatus } from '../../../selectors';
import Header from '../components/header';
import { injectIntl } from 'react-intl';

const makeMapStateToProps = () => {
  const getStatus = makeGetStatus();

  const mapStateToProps = (state, { statusId }) => ({
    status: getStatus(state, { id: statusId }),
  });

  return mapStateToProps;
};

export default injectIntl(connect(makeMapStateToProps)(Header));
