import React from 'react';
import PropTypes from 'prop-types';
import Icon from 'mastodon/components/icon';

const IconWithBadge = ({ id, count, countMax, issueBadge, className }) => {
  const formatNumber = num => num > countMax ? `${countMax}+` : num;

  return (
    <i className='icon-with-badge'>
      <Icon id={id} fixedWidth className={className} />
      {count > 0 && <i className='icon-with-badge__badge'>{formatNumber(count)}</i>}
      {issueBadge && <i className='icon-with-badge__issue-badge' />}
    </i>
  )
};

IconWithBadge.propTypes = {
  id: PropTypes.string.isRequired,
  count: PropTypes.number.isRequired,
  countMax: PropTypes.number,
  issueBadge: PropTypes.bool,
  className: PropTypes.string,
};

IconWithBadge.defaultProps = {
  countMax: 40,
};

export default IconWithBadge;
