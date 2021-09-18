import React, { Fragment } from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { makeGetAccount } from 'mastodon/selectors';
import ImmutablePropTypes, { list } from 'react-immutable-proptypes';
import ImmutablePureComponent from 'react-immutable-pure-component';
import Avatar from 'mastodon/components/avatar';
import { FormattedMessage, injectIntl } from 'react-intl';

const makeMapStateToProps = () => {
  const getAccount = makeGetAccount();

  const mapStateToProps = (state, { accountId }) => ({
    account: getAccount(state, accountId),
  });

  return mapStateToProps;
};

@connect(makeMapStateToProps)
class Account extends ImmutablePureComponent {

  static propTypes = {
    account: ImmutablePropTypes.map,
  };

  render () {
    const { account } = this.props;

    if ( !account ) {
      return <Fragment></Fragment>;
    }

    return (
      <div className='account-popup__wapper'>
        <div className='account-popup__avatar-wrapper'><Avatar account={account} size={14} /></div>
        <bdi><strong className='account-popup__display-name__html' dangerouslySetInnerHTML={{ __html: account.get('display_name_html') }} /></bdi>
      </div>
    );
  }
}

const ACCOUNT_POPUP_ROWS_MAX = 10;

@injectIntl
export default class AccountPopup extends ImmutablePureComponent {

  static propTypes = {
    accountIds: ImmutablePropTypes.list.isRequired,
    style: PropTypes.object,
    placement: PropTypes.string,
    arrowOffsetLeft: PropTypes.string,
    arrowOffsetTop: PropTypes.string,
  };

  render () {
    const { accountIds, placement } = this.props;
    var { arrowOffsetLeft, arrowOffsetTop, style } = this.props;
    const OFFSET = 6;

    if (placement === 'top') {
      arrowOffsetTop = String(parseInt(arrowOffsetTop ?? '0') - OFFSET);
      style = { ...style, top: style.top - OFFSET };
    } else if (placement === 'bottom') {
      arrowOffsetTop = String(parseInt(arrowOffsetTop ?? '0') + OFFSET);
      style = { ...style, top: style.top + OFFSET };
    } else if (placement === 'left') {
      arrowOffsetLeft = String(parseInt(arrowOffsetLeft ?? '0') - OFFSET);
      style = { ...style, left: style.left - OFFSET };
    } else if (placement === 'right') {
      arrowOffsetLeft = String(parseInt(arrowOffsetLeft ?? '0') + OFFSET);
      style = { ...style, left: style.left + OFFSET };
    }
  
    return (
      <div className={`dropdown-menu account-popup ${placement}`} style={{ ...style}}>
        <div className={`dropdown-menu__arrow account-popup__arrow ${placement}`} style={{ left: arrowOffsetLeft, top: arrowOffsetTop }} />
        {accountIds.take(ACCOUNT_POPUP_ROWS_MAX).map(accountId => <Account key={accountId} accountId={accountId} />)}
        {accountIds.size > ACCOUNT_POPUP_ROWS_MAX && <div className='account-popup__wapper'><bdi><strong className='account-popup__display-name__html'><FormattedMessage id='account_popup.more_users' defaultMessage='({number, plural, one {# other user} other {# other users}})' values={{ number: accountIds.size - ACCOUNT_POPUP_ROWS_MAX}} children={msg=> <>{msg}</>} /></strong></bdi></div>}
      </div>
    );
  }
}
