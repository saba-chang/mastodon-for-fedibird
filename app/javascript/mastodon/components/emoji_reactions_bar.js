import React, { Fragment } from 'react';
import PropTypes from 'prop-types';
import ImmutablePropTypes from 'react-immutable-proptypes';
import ImmutablePureComponent from 'react-immutable-pure-component';
import classNames from 'classnames';
import Emoji from './emoji';
import unicodeMapping from 'mastodon/features/emoji/emoji_unicode_mapping_light';
import TransitionMotion from 'react-motion/lib/TransitionMotion';
import AnimatedNumber from 'mastodon/components/animated_number';
import { reduceMotion, me } from 'mastodon/initial_state';
import spring from 'react-motion/lib/spring';

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
  }

  handleMouseEnter = () => this.setState({ hovered: true })

  handleMouseLeave = () => this.setState({ hovered: false })

  render () {
    const { emojiReaction, status, myReaction } = this.props;

    let shortCode = emojiReaction.get('name');

    if (unicodeMapping[shortCode]) {
      shortCode = unicodeMapping[shortCode].shortCode;
    }

    return (
      <button className={classNames('reactions-bar__item', { active: myReaction })} disabled={status.get('emoji_reactioned') && !myReaction} onClick={this.handleClick} onMouseEnter={this.handleMouseEnter} onMouseLeave={this.handleMouseLeave} title={`:${shortCode}:`} style={this.props.style}>
        <span className='reactions-bar__item__emoji'><Emoji hovered={this.state.hovered} emoji={emojiReaction.get('name')} emojiMap={this.props.emojiMap} url={emojiReaction.get('url')} static_url={emojiReaction.get('static_url')} /></span>
        <span className='reactions-bar__item__count'><AnimatedNumber value={emojiReaction.get('count')} /></span>
      </button>
    );
  }
  
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
          myReaction: emoji_reaction.get('account_ids', []).includes(me),
        },
        style: { scale: reduceMotion ? 1 : spring(1, { stiffness: 150, damping: 13 }) },
      };
    }).toArray();

    return (
      <TransitionMotion styles={styles} willEnter={this.willEnter} willLeave={this.willLeave}>
        {items => (
          <div className='reactions-bar'>
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
