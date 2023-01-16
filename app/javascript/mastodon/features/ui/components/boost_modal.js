import React from 'react';
import { connect } from 'react-redux';
import ImmutablePropTypes from 'react-immutable-proptypes';
import PropTypes from 'prop-types';
import { defineMessages, injectIntl, FormattedMessage } from 'react-intl';
import Button from '../../../components/button';
import StatusContent from '../../../components/status_content';
import Avatar from '../../../components/avatar';
import AbsoluteTimestamp from '../../../components/absolute_timestamp';
import RelativeTimestamp from '../../../components/relative_timestamp';
import DisplayName from '../../../components/display_name';
import ImmutablePureComponent from 'react-immutable-pure-component';
import Icon from 'mastodon/components/icon';
import AttachmentList from 'mastodon/components/attachment_list';
import PrivacyDropdown from 'mastodon/features/compose/components/privacy_dropdown';
import classNames from 'classnames';
import { changeBoostPrivacy } from 'mastodon/actions/boosts';
import { disableRelativeTime } from 'mastodon/initial_state';

const messages = defineMessages({
  cancel_reblog: { id: 'status.cancel_reblog_private', defaultMessage: 'Unboost' },
  reblog: { id: 'status.reblog', defaultMessage: 'Boost' },
  public_short: { id: 'privacy.public.short', defaultMessage: 'Public' },
  unlisted_short: { id: 'privacy.unlisted.short', defaultMessage: 'Unlisted' },
  private_short: { id: 'privacy.private.short', defaultMessage: 'Followers-only' },
  mutual_short: { id: 'privacy.mutual.short', defaultMessage: 'Mutual-followers-only' },
  limited_short: { id: 'privacy.limited.short', defaultMessage: 'Circle' },
  direct_short: { id: 'privacy.direct.short', defaultMessage: 'Direct' },
});

const mapStateToProps = state => {
  return {
    privacy: state.getIn(['boosts', 'new', 'privacy']),
    prohibitedVisibilities: state.getIn(['compose', 'prohibited_visibilities']),
  };
};

const mapDispatchToProps = dispatch => {
  return {
    onChangeBoostPrivacy(value) {
      dispatch(changeBoostPrivacy(value));
    },
  };
};

export default @connect(mapStateToProps, mapDispatchToProps, null, { forwardRef: true })
@injectIntl
class BoostModal extends ImmutablePureComponent {

  static contextTypes = {
    router: PropTypes.object,
  };

  static propTypes = {
    status: ImmutablePropTypes.map.isRequired,
    onReblog: PropTypes.func.isRequired,
    onClose: PropTypes.func.isRequired,
    onChangeBoostPrivacy: PropTypes.func.isRequired,
    privacy: PropTypes.string.isRequired,
    intl: PropTypes.object.isRequired,
  };

  componentDidMount() {
    this.button.focus();
  }

  handleReblog = () => {
    this.props.onReblog(this.props.status, this.props.privacy);
    this.props.onClose();
  }

  handleAccountClick = (e) => {
    if (e.button === 0 && !(e.ctrlKey || e.metaKey)) {
      const { status } = this.props;
      e.preventDefault();
      this.props.onClose();
      if (status.getIn(['account', 'group'], false)) {
        this.context.router.history.push(`/timelines/groups/${status.getIn(['account', 'id'])}`);
      } else {
        this.context.router.history.push(`/accounts/${status.getIn(['account', 'id'])}`);
      }
    }
  }

  _findContainer = () => {
    return document.getElementsByClassName('modal-root__container')[0];
  };

  setRef = (c) => {
    this.button = c;
  }

  render () {
    const { status, privacy, prohibitedVisibilities, intl } = this.props;
    const buttonText = status.get('reblogged') ? messages.cancel_reblog : messages.reblog;

    const visibilityIconInfo = {
      'public': { icon: 'globe', text: intl.formatMessage(messages.public_short) },
      'unlisted': { icon: 'unlock', text: intl.formatMessage(messages.unlisted_short) },
      'private': { icon: 'lock', text: intl.formatMessage(messages.private_short) },
      'mutual': { icon: 'exchange', text: intl.formatMessage(messages.mutual_short) },
      'limited': { icon: 'user-circle', text: intl.formatMessage(messages.limited_short) },
      'direct': { icon: 'envelope', text: intl.formatMessage(messages.direct_short) },
    };

    const visibilityIcon = visibilityIconInfo[status.get('visibility')];

    return (
      <div className='modal-root__modal boost-modal'>
        <div className='boost-modal__container'>
          <div className={classNames('status', `status-${status.get('visibility')}`, 'light')}>
            <div className='boost-modal__status-header'>
              <div className='boost-modal__status-time'>
                <a href={status.get('url')} className='status__relative-time' target='_blank' rel='noopener noreferrer'>
                  {disableRelativeTime ? <AbsoluteTimestamp timestamp={status.get('created_at')} /> : <RelativeTimestamp timestamp={status.get('created_at')} /> }
                </a>
              </div>
              <span className='status__visibility-icon'><Icon id={visibilityIcon.icon} title={visibilityIcon.text} /></span>

              <a onClick={this.handleAccountClick} href={status.getIn(['account', 'url'])} className='status__display-name'>
                <div className='status__avatar'>
                  <Avatar account={status.get('account')} size={48} />
                </div>

                <DisplayName account={status.get('account')} />
              </a>
            </div>

            <StatusContent status={status} />

            {status.get('media_attachments').size > 0 && (
              <AttachmentList
                compact
                media={status.get('media_attachments')}
              />
            )}
          </div>
        </div>

        <div className='boost-modal__action-bar'>
          <div><FormattedMessage id='boost_modal.combo' defaultMessage='You can press {combo} to skip this next time' values={{ combo: <span>Shift + <Icon id='retweet' /></span> }} /></div>
          {status.get('visibility') !== 'private' && !status.get('reblogged') && (
            <PrivacyDropdown
              noDirect
              value={privacy}
              prohibitedVisibilities={prohibitedVisibilities}
              container={this._findContainer}
              onChange={this.props.onChangeBoostPrivacy}
            />
          )}
          <Button disabled={prohibitedVisibilities?.includes(privacy)} text={intl.formatMessage(buttonText)} onClick={this.handleReblog} ref={this.setRef} />
        </div>
      </div>
    );
  }

}
