import React from 'react';
import PropTypes from 'prop-types';
import classNames from 'classnames';
import Icon from 'mastodon/components/icon';

export default class StackHeader extends React.PureComponent {

  static propTypes = {
    title: PropTypes.node,
    icon: PropTypes.string,
    active: PropTypes.bool,
    onClick: PropTypes.func,
    extraButton: PropTypes.node,
  };

  handleClick = () => {
    this.props.onClick();
  }

  render () {
    const { icon, title, active, extraButton } = this.props;
    let iconElement = '';

    if (icon) {
      iconElement = <Icon id={icon} fixedWidth className='stack-header__icon' />;
    }

    return (
      <h1 className={classNames('stack-header', { active })}>
        <button className='stack-header__button stack-header__button-name' onClick={this.handleClick}>
          {iconElement}
          {title}
        </button>
        {extraButton}
      </h1>
    );
  }

}
