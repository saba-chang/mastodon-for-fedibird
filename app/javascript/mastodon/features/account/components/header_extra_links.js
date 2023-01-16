import React from 'react';
import ImmutablePropTypes from 'react-immutable-proptypes';
import PropTypes from 'prop-types';
import { defineMessages, injectIntl } from 'react-intl';
import ImmutablePureComponent from 'react-immutable-pure-component';
import { me } from 'mastodon/initial_state';
import { counterRenderer } from 'mastodon/components/common_counter';
import ShortNumber from 'mastodon/components/short_number';
import { NavLink } from 'react-router-dom';
import classNames from 'classnames';

const messages = defineMessages({
  secret: { id: 'account.secret', defaultMessage: 'Secret' },
});

export default @injectIntl
class HeaderExtraLinks extends ImmutablePureComponent {

  static propTypes = {
    account: ImmutablePropTypes.map,
    intl: PropTypes.object.isRequired,
  };

  isStatusesPageActive = (match, location) => {
    if (!match) {
      return false;
    }

    return !location.pathname.match(/\/(followers|following|subscribing)\/?$/);
  }

  render () {
    const { account, intl } = this.props;

    if (!account) {
      return null;
    }

    const suspended = account.get('suspended');

    const hide_statuses_count = account.getIn(['other_settings', 'hide_statuses_count'], false);
    const hide_following_count = account.getIn(['other_settings', 'hide_following_count'], false);
    const hide_followers_count = account.getIn(['other_settings', 'hide_followers_count'], false);

    return (
      <div className={classNames('account__header', 'advanced', { inactive: !!account.get('moved') })}>
        <div className='account__header__extra'>
          {!suspended && (
            <div className='account__header__extra__links'>
              <NavLink isActive={this.isStatusesPageActive} activeClassName='active' to={`/accounts/${account.get('id')}/posts`} title={hide_statuses_count ? intl.formatMessage(messages.secret) : intl.formatNumber(account.get('statuses_count'))}>
                <ShortNumber
                  hide={hide_statuses_count}
                  value={account.get('statuses_count')}
                  renderer={counterRenderer('statuses')}
                />
              </NavLink>

              <NavLink exact activeClassName='active' to={`/accounts/${account.get('id')}/following`} title={hide_following_count ? intl.formatMessage(messages.secret) : intl.formatNumber(account.get('following_count'))}>
                <ShortNumber
                  hide={hide_following_count}
                  value={account.get('following_count')}
                  renderer={counterRenderer('following')}
                />
              </NavLink>

              <NavLink exact activeClassName='active' to={`/accounts/${account.get('id')}/followers`} title={hide_followers_count ? intl.formatMessage(messages.secret) : intl.formatNumber(account.get('followers_count'))}>
                <ShortNumber
                  hide={hide_followers_count}
                  value={account.get('followers_count')}
                  renderer={counterRenderer('followers')}
                />
              </NavLink>

              { (me === account.get('id')) && (
                <NavLink exact activeClassName='active' to={`/accounts/${account.get('id')}/subscribing`} title={intl.formatNumber(account.get('subscribing_count'))}>
                  <ShortNumber
                    value={account.get('subscribing_count')}
                    renderer={counterRenderer('subscribers')}
                  />
                </NavLink>
              )}
            </div>
          )}
        </div>
      </div>
    );
  }

}
