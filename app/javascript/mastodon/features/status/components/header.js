import React from 'react';
import ImmutablePropTypes from 'react-immutable-proptypes';
import PropTypes from 'prop-types';
import ImmutablePureComponent from 'react-immutable-pure-component';
import { FormattedMessage } from 'react-intl';
import { NavLink } from 'react-router-dom';

export default class Header extends ImmutablePureComponent {

  static contextTypes = {
    router: PropTypes.object,
  };

  static propTypes = {
    status: ImmutablePropTypes.map,
    hasReference: PropTypes.bool,
    hideTabs: PropTypes.bool,
  };

  render () {
    const { status, hasReference, hideTabs } = this.props;

    if (status === null || !hasReference) {
      return null;
    }

    return (
      <div className='detailed-status__header'>
        {!hideTabs && (
          <div className='detailed-status__section-headline'>
            <NavLink exact to={`/statuses/${status.get('id')}`}><FormattedMessage id='status.thread_with_references' defaultMessage='Thread' /></NavLink>
            <NavLink exact to={`/statuses/${status.get('id')}/references`}><FormattedMessage id='status.reference' defaultMessage='Reference' /></NavLink>
          </div>
        )}
      </div>
    );
  }

}
