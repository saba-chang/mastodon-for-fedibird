import React from 'react';
import { FormattedMessage } from 'react-intl';
import ColumnBackButton from './column_back_button';
import Icon from 'mastodon/components/icon';
import { enableEmptyColumn } from 'mastodon/initial_state';

export default class ColumnBackButtonSlim extends ColumnBackButton {

  render () {
    const { multiColumn } = this.props;

    return (
      <div className='column-back-button--slim'>
        { multiColumn && enableEmptyColumn ? (
          <div role='button' tabIndex='0' onClick={this.handleCloseClick} className='column-back-button column-back-button--slim-button'>
            <Icon id='chevron-left' className='column-back-button__icon' fixedWidth />
            <FormattedMessage id='column_close_button.label' defaultMessage='Back' />
          </div>
        ) : (
          <div role='button' tabIndex='0' onClick={this.handleClick} className='column-back-button column-back-button--slim-button'>
            <Icon id='chevron-left' className='column-back-button__icon' fixedWidth />
            <FormattedMessage id='column_back_button.label' defaultMessage='Back' />
          </div>
        )}
      </div>
    );
  }

}
