class MigrateInstanceTickerTheme < ActiveRecord::Migration[6.1]
  THEME_CONVERSION = {
    nil        => 'default',
    'contrast' => 'contrast',
    'light'    => 'mastodon-light',
  }.freeze

  def up
    result = ActiveRecord::Base.connection.select_all("select u.id, (regexp_matches(s.value, '--- instance-ticker-(type-[0123])'))[1] as type, (regexp_matches(s.value, '--- instance-ticker-type-[0123]-?(contrast|light)'))[1] as theme from users u join settings s on s.thing_id = u.id where s.thing_type = 'User' and var = 'theme' and value ~ '--- instance-ticker-type-[0123]-?(contrast|light)?'").each do |row|
      User.find(row['id']).settings['theme_instance_ticker'] = row['type']
      User.find(row['id']).settings['theme'] = THEME_CONVERSION[row['theme']]
    end
  end

  def down
    # nothing to do
  end
end
