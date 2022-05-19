import React from 'react';
import ImmutablePropTypes from 'react-immutable-proptypes';
import PropTypes from 'prop-types';
import ImmutablePureComponent from 'react-immutable-pure-component';
import { FormattedMessage } from 'react-intl';
import { NavLink } from 'react-router-dom';
import Icon from '../../../components/icon';

export default class Header extends ImmutablePureComponent {

  static contextTypes = {
    router: PropTypes.object,
  };

  static propTypes = {
    status: ImmutablePropTypes.map,
    hideTabs: PropTypes.bool,
  };

  handleStatusBackClick = () => {
    this.context.router.history.push(`/statuses/${this.props.status.get('id')}`);
  };

  handleStatusCloseClick = () => {
    this.context.router.history.push('/empty');
  }

  render () {
    const { status, hideTabs } = this.props;

    if (status === null) {
      return null;
    }

    return (
      <div className='status-reactioned__header'>
        <div className='status-reactioned__back-to-post-button'>
          <button onClick={this.handleStatusBackClick} className='column-header__back-button'>
            <Icon id='chevron-left' className='reactioned-back-button__icon' fixedWidth />
            <FormattedMessage id='column_back_button_to_pots.label' defaultMessage='Back to post detail' />
          </button>
        </div>

        {!hideTabs && (
          <div className='status-reactioned__section-headline'>
            <NavLink exact to={`/statuses/${status.get('id')}/reblogs`}><FormattedMessage id='status.reblog' defaultMessage='Boost' /></NavLink>
            <NavLink exact to={`/statuses/${status.get('id')}/favourites`}><FormattedMessage id='status.favourite' defaultMessage='Favourite' /></NavLink>
            <NavLink exact to={`/statuses/${status.get('id')}/emoji_reactions`}><FormattedMessage id='status.emoji' defaultMessage='Emoji' /></NavLink>
            <NavLink exact to={`/statuses/${status.get('id')}/referred_by`}><FormattedMessage id='status.referred_by' defaultMessage='Referred' /></NavLink>
          </div>
        )}
      </div>
    );
  }

}
