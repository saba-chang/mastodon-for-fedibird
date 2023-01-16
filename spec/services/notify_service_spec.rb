require 'rails_helper'

RSpec.describe NotifyService, type: :service do
  subject do
    -> { described_class.new.call(recipient, type, activity) }
  end

  let(:user) { Fabricate(:user) }
  let(:recipient) { user.account }
  let(:sender) { Fabricate(:account, domain: 'example.com') }
  let(:activity) { Fabricate(:follow, account: sender, target_account: recipient) }
  let(:type) { :follow }

  it { is_expected.to change(Notification, :count).by(1) }

  it 'does not notify when sender is blocked' do
    recipient.block!(sender)
    is_expected.to_not change(Notification, :count)
  end

  it 'does not notify when sender is muted with hide_notifications' do
    recipient.mute!(sender, notifications: true)
    is_expected.to_not change(Notification, :count)
  end

  it 'does notify when sender is muted without hide_notifications' do
    recipient.mute!(sender, notifications: false)
    is_expected.to change(Notification, :count)
  end

  it 'does not notify when sender\'s domain is blocked' do
    recipient.block_domain!(sender.domain)
    is_expected.to_not change(Notification, :count)
  end

  it 'does still notify when sender\'s domain is blocked but sender is followed' do
    recipient.block_domain!(sender.domain)
    recipient.follow!(sender)
    is_expected.to change(Notification, :count)
  end

  it 'does not notify when sender is silenced and not followed' do
    sender.silence!
    is_expected.to_not change(Notification, :count)
  end

  it 'does not notify when recipient is suspended' do
    recipient.suspend!
    is_expected.to_not change(Notification, :count)
  end

  context 'for direct messages' do
    let(:activity) { Fabricate(:mention, account: recipient, status: Fabricate(:status, account: sender, visibility: :direct)) }
    let(:type)     { :mention }

    before do
      user.settings.interactions = user.settings.interactions.merge('must_be_following_dm' => enabled)
    end

    context 'if recipient is supposed to be following sender' do
      let(:enabled) { true }

      it 'does not notify' do
        is_expected.to_not change(Notification, :count)
      end

      context 'if the message chain initiated by recipient, but is not direct message' do
        let(:reply_to) { Fabricate(:status, account: recipient) }
        let(:activity) { Fabricate(:mention, account: recipient, status: Fabricate(:status, account: sender, visibility: :direct, thread: reply_to)) }

        it 'does not notify' do
          is_expected.to_not change(Notification, :count)
        end
      end

      context 'if the message chain initiated by recipient and is direct message' do
        let(:reply_to) { Fabricate(:status, account: recipient, visibility: :direct) }
        let(:activity) { Fabricate(:mention, account: recipient, status: Fabricate(:status, account: sender, visibility: :direct, thread: reply_to)) }

        it 'does notify' do
          is_expected.to change(Notification, :count)
        end
      end
    end

    context 'if recipient is NOT supposed to be following sender' do
      let(:enabled) { false }

      it 'does notify' do
        is_expected.to change(Notification, :count)
      end
    end
  end

  describe 'reblogs' do
    let(:status)   { Fabricate(:status, account: Fabricate(:account)) }
    let(:activity) { Fabricate(:status, account: sender, reblog: status) }
    let(:type)     { :reblog }

    it 'shows reblogs by default' do
      recipient.follow!(sender)
      is_expected.to change(Notification, :count)
    end

    it 'shows reblogs when explicitly enabled' do
      recipient.follow!(sender, reblogs: true)
      is_expected.to change(Notification, :count)
    end

    it 'shows reblogs when disabled' do
      recipient.follow!(sender, reblogs: false)
      is_expected.to change(Notification, :count)
    end
  end

  context do
    let(:asshole)  { Fabricate(:account, username: 'asshole') }
    let(:reply_to) { Fabricate(:status, account: asshole) }
    let(:activity) { Fabricate(:mention, account: recipient, status: Fabricate(:status, account: sender, thread: reply_to)) }
    let(:type)     { :mention }

    it 'does not notify when conversation is muted' do
      recipient.mute_conversation!(activity.status.conversation)
      is_expected.to_not change(Notification, :count)
    end

    it 'does not notify when it is a reply to a blocked user' do
      recipient.block!(asshole)
      is_expected.to_not change(Notification, :count)
    end
  end

  context do
    let(:sender) { recipient }

    it 'does not notify when recipient is the sender' do
      is_expected.to_not change(Notification, :count)
    end
  end

  describe 'email' do
    before do
      ActionMailer::Base.deliveries.clear

      notification_emails = user.settings.notification_emails
      user.settings.notification_emails = notification_emails.merge('follow' => enabled)
    end

    context 'when email notification is enabled' do
      let(:enabled) { true }

      it 'sends email' do
        is_expected.to change(ActionMailer::Base.deliveries, :count).by(1)
      end
    end

    context 'when email notification is disabled' do
      let(:enabled) { false }

      it "doesn't send email" do
        is_expected.to_not change(ActionMailer::Base.deliveries, :count).from(0)
      end
    end

    context 'with mentions' do
      let(:type) { :mention }

      before do
        user.settings.notification_emails = user.settings.notification_emails.merge('mention' => true)
        user.settings.interactions        = user.settings.interactions.merge('must_be_dm_to_send_email' => enabled)
      end

      context 'if must_be_dm_to_send_email is true' do
        let(:enabled) { true }

        describe 'with direct messsages' do
          let(:activity) { Fabricate(:mention, account: recipient, status: Fabricate(:status, account: sender, visibility: :direct)) }

          it 'sends email' do
            is_expected.to change(ActionMailer::Base.deliveries, :count).by(1)
          end
        end

        describe 'with public messsages' do
          let(:activity) { Fabricate(:mention, account: recipient, status: Fabricate(:status, account: sender, visibility: :public)) }

          it "doesn't send email" do
            is_expected.to_not change(ActionMailer::Base.deliveries, :count).from(0)
          end
        end
      end

      context 'if must_be_dm_to_send_email is false' do
        let(:enabled) { false }

        describe 'with direct messsages' do
          let(:activity) { Fabricate(:mention, account: recipient, status: Fabricate(:status, account: sender, visibility: :direct)) }

          it 'sends email' do
            is_expected.to change(ActionMailer::Base.deliveries, :count).by(1)
          end
        end

        describe 'with public messsages' do
          let(:activity) { Fabricate(:mention, account: recipient, status: Fabricate(:status, account: sender, visibility: :public)) }

          it 'sends email' do
            is_expected.to change(ActionMailer::Base.deliveries, :count).by(1)
          end
        end
      end
    end
  end
end
