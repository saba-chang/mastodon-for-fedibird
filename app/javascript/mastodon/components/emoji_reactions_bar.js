import React, { Fragment } from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { makeGetAccount } from 'mastodon/selectors';
import ImmutablePropTypes, { list } from 'react-immutable-proptypes';
import ImmutablePureComponent from 'react-immutable-pure-component';
import { List } from 'immutable';
import classNames from 'classnames';
import Emoji from './emoji';
import unicodeMapping from 'mastodon/features/emoji/emoji_unicode_mapping_light';
import TransitionMotion from 'react-motion/lib/TransitionMotion';
import AnimatedNumber from 'mastodon/components/animated_number';
import { reduceMotion, me } from 'mastodon/initial_state';
import spring from 'react-motion/lib/spring';
import Avatar from 'mastodon/components/avatar';
import Overlay from 'react-overlays/lib/Overlay';
import { FormattedMessage, injectIntl } from 'react-intl';
import { isUserTouching } from 'mastodon/is_mobile';

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
class AccountPopup extends ImmutablePureComponent {

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

class EmojiReaction extends ImmutablePureComponent {

  static propTypes = {
    status: ImmutablePropTypes.map.isRequired,
    emojiReaction: ImmutablePropTypes.map.isRequired,
    myReaction: PropTypes.bool.isRequired,
    addEmojiReaction: PropTypes.func.isRequired,
    removeEmojiReaction: PropTypes.func.isRequired,
    emojiMap: ImmutablePropTypes.map.isRequired,
    style: PropTypes.object,
  };

  state = {
    hovered: false,
  };

  handleClick = () => {
    const { emojiReaction, status, addEmojiReaction, removeEmojiReaction, myReaction } = this.props;

    if (myReaction) {
      removeEmojiReaction(status);
    } else {
      addEmojiReaction(status, emojiReaction.get('name'), emojiReaction.get('domain', null), emojiReaction.get('url', null), emojiReaction.get('static_url', null));
    }
  };

  handleMouseEnter = ({ target }) => {
    const { top } = target.getBoundingClientRect();

    this.setState({
      hovered: true,
      placement: top * 2 < innerHeight ? 'bottom' : 'top',
    });
  };

  handleMouseLeave = () => {
    this.setState({
      hovered: false,
    });
  };

  setTargetRef = c => {
    this.target = c;
  };

  findTarget = () => {
    return this.target;
  };

  componentDidMount () {
    this.target?.addEventListener('mouseenter', this.handleMouseEnter, { capture: true });
    this.target?.addEventListener('mouseleave', this.handleMouseLeave, false);
  }

  componentWillUnmount () {
    this.target?.removeEventListener('mouseenter', this.handleMouseEnter, { capture: true });
    this.target?.removeEventListener('mouseleave', this.handleMouseLeave, false);
  }

  render () {
    const { emojiReaction, status, myReaction } = this.props;

    let shortCode = emojiReaction.get('name');

    if (unicodeMapping[shortCode]) {
      shortCode = unicodeMapping[shortCode].shortCode;
    }

    return (
      <Fragment>
        <div className='reactions-bar__item-wrapper' ref={this.setTargetRef}>
          <button className={classNames('reactions-bar__item', { active: myReaction })} disabled={status.get('emoji_reactioned') && !myReaction} onClick={this.handleClick} title={`:${shortCode}:`} style={this.props.style}>
            <span className='reactions-bar__item__emoji'><Emoji hovered={this.state.hovered} emoji={emojiReaction.get('name')} emojiMap={this.props.emojiMap} url={emojiReaction.get('url')} static_url={emojiReaction.get('static_url')} /></span>
            <span className='reactions-bar__item__count'><AnimatedNumber value={emojiReaction.get('count')} /></span>
          </button>
        </div>
        {!isUserTouching() &&
        <Overlay show={this.state.hovered} placement={this.state.placement} target={this.findTarget}>
          <AccountPopup accountIds={emojiReaction.get('account_ids', List())} />
        </Overlay>
        }
      </Fragment>
    );
  };
  
}

export default class EmojiReactionsBar extends ImmutablePureComponent {

  static propTypes = {
    status: ImmutablePropTypes.map.isRequired,
    addEmojiReaction: PropTypes.func.isRequired,
    removeEmojiReaction: PropTypes.func.isRequired,
    emojiMap: ImmutablePropTypes.map.isRequired,
  };

  willEnter () {
    return { scale: reduceMotion ? 1 : 0 };
  }

  willLeave () {
    return { scale: reduceMotion ? 0 : spring(0, { stiffness: 170, damping: 26 }) };
  }

  render () {
    const { status } = this.props;
    const emoji_reactions = status.get("emoji_reactions")
    const visibleReactions = emoji_reactions.filter(x => x.get('count') > 0);

    if (visibleReactions.isEmpty() ) {
      return <Fragment></Fragment>;
    }

    const styles = visibleReactions.map(emoji_reaction => {
      const domain = emoji_reaction.get('domain', '');

      return {
        key: `${emoji_reaction.get('name')}${domain ? `@${domain}` : ''}`,
        data: {
          emojiReaction: emoji_reaction,
          myReaction: emoji_reaction.get('account_ids', List()).includes(me),
        },
        style: { scale: reduceMotion ? 1 : spring(1, { stiffness: 150, damping: 13 }) },
      };
    }).toArray();

    return (
      <TransitionMotion styles={styles} willEnter={this.willEnter} willLeave={this.willLeave}>
        {items => (
          <div className='reactions-bar emoji-reactions-bar'>
            {items.map(({ key, data, style }) => (
              <EmojiReaction
                key={key}
                emojiReaction={data.emojiReaction}
                myReaction={data.myReaction}
                style={{ transform: `scale(${style.scale})`, position: style.scale < 0.5 ? 'absolute' : 'static' }}
                status={this.props.status}
                addEmojiReaction={this.props.addEmojiReaction}
                removeEmojiReaction={this.props.removeEmojiReaction}
                emojiMap={this.props.emojiMap}
              />
            ))}
          </div>
        )}
      </TransitionMotion>
    );
  }

}
