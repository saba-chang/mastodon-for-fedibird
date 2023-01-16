# frozen_string_literal: true

require 'singleton'

class Formatter
  include Singleton
  include RoutingHelper

  include ActionView::Helpers::TextHelper

  DISALLOWED_BOUNDING_REGEX = /[[:alnum:]:]/.freeze

  def format(status, **options)
    if status.reblog?
      prepend_reblog = status.reblog.account.acct
      status         = status.proper
    else
      prepend_reblog = false
    end

    raw_content = status.text

    if options[:inline_poll_options] && status.preloadable_poll
      raw_content = raw_content + "\n\n" + status.preloadable_poll.options.map { |title| "[ ] #{title}" }.join("\n")
    end

    return '' if raw_content.blank?

    unless status.local?
      html = reformat(raw_content)
      html = apply_inner_link(html)
      html = apply_reference_link(html, status)
      html = encode_custom_emojis(html, status.emojis, options[:autoplay]) if options[:custom_emojify]
      html = nyaize_html(html) if options[:nyaize]
      return html.html_safe # rubocop:disable Rails/OutputSafety
    end

    linkable_accounts = status.active_mentions.map(&:account)
    linkable_accounts << status.account

    html = raw_content
    html = "RT @#{prepend_reblog} #{html}" if prepend_reblog
    html = encode_and_link_urls(html, linkable_accounts)
    html = encode_custom_emojis(html, status.emojis, options[:autoplay]) if options[:custom_emojify]
    html = simple_format(html, {}, sanitize: false)
    html = quotify(html, status) if status.quote? && !options[:escape_quotify]
    html = add_compatible_reference_link(html, status) if status.references.exists?
    html = nyaize_html(html) if options[:nyaize]
    html = html.delete("\n")

    html.html_safe # rubocop:disable Rails/OutputSafety
  end

  def format_in_quote(status, **options)
    html = format(status)
    return '' if html.empty?
    doc = Nokogiri::HTML.parse(html, nil, 'utf-8')
    html = doc.css('body')[0].inner_html
    html.sub!(/^<p>(.+)<\/p>$/, '\1')
    html = Sanitize.clean(html).delete("\n").truncate(150)
    html = encode_custom_emojis(html, status.emojis) if options[:custom_emojify]
    html.html_safe # rubocop:disable Rails/OutputSafety
  end

  def reformat(html)
    sanitize(html, Sanitize::Config::MASTODON_STRICT)
  rescue ArgumentError
    ''
  end

  def plaintext(status)
    return status.text if status.local?

    text = status.text.gsub(/(<br \/>|<br>|<\/p>)+/) { |match| "#{match}\n" }
    text = remove_reference_link(text)
    strip_tags(text)
  end

  def simplified_format(account, **options)
    html = account.local? ? linkify(account.note) : reformat(account.note)
    html = encode_custom_emojis(html, account.emojis, options[:autoplay]) if options[:custom_emojify]
    html.html_safe # rubocop:disable Rails/OutputSafety
  end

  def sanitize(html, config)
    Sanitize.fragment(html, config)
  end

  def format_spoiler(status, **options)
    html = encode(status.spoiler_text)
    html = encode_custom_emojis(html, status.emojis, options[:autoplay])
    html.html_safe # rubocop:disable Rails/OutputSafety
  end

  def format_poll_option(status, option, **options)
    html = encode(option.title)
    html = encode_custom_emojis(html, status.emojis, options[:autoplay])
    html.html_safe # rubocop:disable Rails/OutputSafety
  end

  def format_display_name(account, **options)
    html = encode(account.display_name.presence || account.username)
    html = encode_custom_emojis(html, account.emojis, options[:autoplay]) if options[:custom_emojify]
    html.html_safe # rubocop:disable Rails/OutputSafety
  end

  def format_field(account, str, **options)
    html = account.local? ? encode_and_link_urls(str, me: true, with_domain: true) : reformat(str)
    html = encode_custom_emojis(html, account.emojis, options[:autoplay]) if options[:custom_emojify]
    html.html_safe # rubocop:disable Rails/OutputSafety
  end

  def linkify(text)
    html = encode_and_link_urls(text)
    html = simple_format(html, {}, sanitize: false)
    html = html.delete("\n")

    html.html_safe # rubocop:disable Rails/OutputSafety
  end

  private

  def html_entities
    @html_entities ||= HTMLEntities.new
  end

  def encode(html)
    html_entities.encode(html)
  end

  def encode_and_link_urls(html, accounts = nil, options = {})
    entities = utf8_friendly_extractor(html, extract_url_without_protocol: false)

    if accounts.is_a?(Hash)
      options  = accounts
      accounts = nil
    end

    rewrite(html.dup, entities) do |entity|
      if entity[:url]
        link_to_url(entity, options)
      elsif entity[:hashtag]
        link_to_hashtag(entity)
      elsif entity[:screen_name]
        link_to_mention(entity, accounts, options)
      end
    end
  end

  def count_tag_nesting(tag)
    if tag[1] == '/' then -1
    elsif tag[-2] == '/' then 0
    else 1
    end
  end

  # rubocop:disable Metrics/BlockNesting
  def encode_custom_emojis(html, emojis, animate = false)
    return html if emojis.empty?

    emoji_map = emojis.each_with_object({}) { |e, h| h[e.shortcode] = [full_asset_url(e.image.url), full_asset_url(e.image.url(:static))] }

    tree = Nokogiri::HTML.fragment(html)
    tree.xpath('./text()|.//text()[not(ancestor[@class="invisible"])]').to_a.each do |node|
      i                     = -1
      inside_shortname      = false
      shortname_start_index = -1
      last_index            = 0
      text                  = node.content
      result                = Nokogiri::XML::NodeSet.new(tree.document)

      while i + 1 < text.size
        i += 1

        if inside_shortname && text[i] == ':'
          inside_shortname = false
          shortcode = text[shortname_start_index + 1..i - 1]
          char_after = text[i + 1]

          next unless (char_after.nil? || !DISALLOWED_BOUNDING_REGEX.match?(char_after)) && (emoji = emoji_map[shortcode])

          original_url, static_url = emoji

          result << Nokogiri::XML::Text.new(text[last_index..shortname_start_index - 1], tree.document) if shortname_start_index.positive?

          result << Nokogiri::HTML.fragment(
            if animate
              image_tag(original_url, draggable: false, class: 'emojione', alt: ":#{shortcode}:", title: ":#{shortcode}:")
            else
              image_tag(original_url, draggable: false, class: 'emojione custom-emoji', alt: ":#{shortcode}:", title: ":#{shortcode}:", data: { original: original_url, static: static_url })
            end
          )

          last_index = i + 1
        elsif text[i] == ':' && (i.zero? || !DISALLOWED_BOUNDING_REGEX.match?(text[i - 1]))
          inside_shortname = true
          shortname_start_index = i
        end
      end

      result << Nokogiri::XML::Text.new(text[last_index..-1], tree.document)
      node.replace(result)
    end

    tree.to_html
  end
  # rubocop:enable Metrics/BlockNesting

  def quotify(html, status)
    url = ActivityPub::TagManager.instance.url_for(status.quote)
    link = encode_and_link_urls(url)
    html.sub(/(<[^>]+>)\z/, "<span class=\"quote-inline\"><br/>QT: #{link}</span>\\1")
  end

  def add_compatible_reference_link(html, status)
    url = references_short_account_status_url(status.account, status)
    link = "<a href=\"#{url}\" target=\"_blank\" rel=\"noopener noreferrer\" class=\"status-link unhandled-link\" data-status-id=\"#{status.id}\">#{I18n.t('status_references.link_text')}</a>"
    html.sub(/<\/p>\z/, "<span class=\"reference-link-inline\"> #{link}</span></p>")
  end

  def nyaize_html(html)
    inside_anchor = false

    html.split(/(<.+?>)/).compact.map do |x|
      if x.match(/^<a/)
        inside_anchor = true
      elsif x == '</a>'
        inside_anchor = false
      end

      if inside_anchor || x[0] == '<'
        x
      else
        x.split(/(:.+?:)/).compact.map do |x|
          if x[0] == ':'
            x
          else
            nyaize(x)
          end
        end.join
      end
    end.join
  end

  def nyaize(text)
    text
      # ja-JP
      .gsub(/な/, "にゃ").gsub(/ナ/, "ニャ").gsub(/ﾅ/, "ﾆｬ")
      # en-US
      .gsub(/(?<=n)a/i) { |x| x == 'A' ? 'YA' : 'ya' }
      .gsub(/(?<=morn)ing/i) { |x| x == 'ING' ? 'YAN' : 'yan' }
      .gsub(/(?<=every)one/i) { |x| x == 'ONE' ? 'NYAN' : 'nyan' }
      # vko-KR
      .gsub(/[나-낳]/) { |c| (c.ord + '냐'.ord - '나'.ord).chr }
      .gsub(/(다)|(다(?=\.))|(다(?= ))|(다(?=!))|(다(?=\?))/m, '다냥')
      .gsub(/(야(?=\?))|(야$)|(야(?= ))/m, '냥')
  end

  def rewrite(text, entities)
    text = text.to_s

    # Sort by start index
    entities = entities.sort_by do |entity|
      indices = entity.respond_to?(:indices) ? entity.indices : entity[:indices]
      indices.first
    end

    result = []

    last_index = entities.reduce(0) do |index, entity|
      indices = entity.respond_to?(:indices) ? entity.indices : entity[:indices]
      result << encode(text[index...indices.first])
      result << yield(entity)
      indices.last
    end

    result << encode(text[last_index..-1])

    result.flatten.join
  end

  def utf8_friendly_extractor(text, options = {})
    # Note: I couldn't obtain list_slug with @user/list-name format
    # for mention so this requires additional check
    special = Extractor.extract_urls_with_indices(text, options)
    standard = Extractor.extract_entities_with_indices(text, options)
    extra = Extractor.extract_extra_uris_with_indices(text, options)

    Extractor.remove_overlapping_entities(special + standard + extra)
  end

  def class_append(c, items)
    (c || '').split.concat(items).uniq.join(' ')
  end

  def link_to_url(entity, options = {})
    url        = Addressable::URI.parse(entity[:url])
    html_attrs = { target: '_blank', rel: 'nofollow noopener noreferrer' }

    html_attrs[:rel] = "me #{html_attrs[:rel]}" if options[:me]

    status  = url_to_holding_status(url.normalize.to_s)
    account = status&.account
    account = url_to_holding_account(url.normalize.to_s) if status.nil?

    if status.present? && account.present?
      html_attrs[:class]                      = class_append(html_attrs[:class], ['status-url-link'])
      html_attrs[:'data-status-id']           = status.id
      html_attrs[:'data-status-account-acct'] = account.acct
    elsif account.present?
      html_attrs[:class]                     = class_append(html_attrs[:class], ['account-url-link'])
      html_attrs[:'data-account-id']         = account.id
      html_attrs[:'data-account-actor-type'] = account.actor_type
      html_attrs[:'data-account-acct']       = account.acct
    end

    Twitter::TwitterText::Autolink.send(:link_to_text, entity, link_html(entity[:url]), url, html_attrs)
  rescue Addressable::URI::InvalidURIError, IDN::Idna::IdnaError
    encode(entity[:url])
  end

  def apply_inner_link(html)
    doc = Nokogiri::HTML.parse(html, nil, 'utf-8')
    doc.css('a').map do |x|
      status  = url_to_holding_status(x['href'])
      account = status&.account
      account = url_to_holding_account(x['href']) if status.nil?

      if status.present? && account.present?
        x.add_class('status-url-link')
        x['data-status-id']           = status.id
        x['data-status-account-acct'] = account.acct
      elsif account.present?
        x.add_class('account-url-link')
        x['data-account-id']         = account.id
        x['data-account-actor-type'] = account.actor_type
        x['data-account-acct']       = account.acct
      end
    end
    html = doc.css('body')[0]&.inner_html || ''
    html.html_safe # rubocop:disable Rails/OutputSafety
  end

  def remove_reference_link(html)
    doc = Nokogiri::HTML.parse(html, nil, 'utf-8')
    doc.at_css('span.reference-link-inline')&.unlink 
    html = doc.at_css('body')&.inner_html || ''
    html.html_safe # rubocop:disable Rails/OutputSafety
  end

  def apply_reference_link(html, status)
    doc = Nokogiri::HTML.parse(html, nil, 'utf-8')

    reference_link_url = nil

    doc.at_css('span.reference-link-inline').tap do |x|
      if x.present?
        reference_link_url = x.at_css('a')&.attr('href')
        x.unlink 
      end
    end

    if status.references.exists?
      ref_span   = Nokogiri::XML::Node.new("span", doc)
      ref_anchor = Nokogiri::XML::Node.new("a", doc)
      ref_anchor.add_class('status-link unhandled-link')
      ref_anchor['href']           = reference_link_url || status.url
      ref_anchor['target']         = '_blank'
      ref_anchor['rel']            = 'noopener noreferrer'
      ref_anchor['data-status-id'] = status.id
      ref_anchor.content           = I18n.t('status_references.link_text')
      ref_span.content             = ' '
      ref_span.add_class('reference-link-inline')
      ref_span.add_child(ref_anchor)
      (doc.at_css('body > p:last-child') || doc.at_css('body'))&.add_child(ref_span)
    end

    html = doc.at_css('body')&.inner_html || ''
    html.html_safe # rubocop:disable Rails/OutputSafety
  end

  def normalize_url_without_fragment(url)
    return if url.nil?

    uri = Addressable::URI.parse(url).normalize
    uri.fragment = nil
    uri.to_s
  end

  def url_to_holding_account(url)
    url = normalize_url_without_fragment(url)

    return if url.nil?

    EntityCache.instance.holding_account(url)
  end

  def url_to_holding_status(url)
    url = normalize_url_without_fragment(url)

    return if url.nil?

    EntityCache.instance.holding_status(url)
  end

  def link_to_mention(entity, linkable_accounts, options = {})
    acct = entity[:screen_name]

    return link_to_account(acct, options) unless linkable_accounts

    same_username_hits = 0
    account = nil
    username, domain = acct.split('@')
    domain = nil if TagManager.instance.local_domain?(domain)

    linkable_accounts.each do |item|
      same_username = item.username.casecmp(username).zero?
      same_domain   = item.domain.nil? ? domain.nil? : item.domain.casecmp(domain)&.zero?

      if same_username && !same_domain
        same_username_hits += 1
      elsif same_username && same_domain
        account = item
      end
    end

    account ? mention_html(account, with_domain: same_username_hits.positive? || options[:with_domain]) : "@#{encode(acct)}"
  end

  def link_to_account(acct, options = {})
    username, domain = acct.split('@')

    domain  = nil if TagManager.instance.local_domain?(domain)
    account = EntityCache.instance.mention(username, domain)

    account ? mention_html(account, with_domain: options[:with_domain]) : "@#{encode(acct)}"
  end

  def link_to_hashtag(entity)
    hashtag_html(entity[:hashtag])
  end

  def link_html(url)
    url    = Addressable::URI.parse(url).to_s
    prefix = url.match(/\A(https?:\/\/(www\.)?|xmpp:)/).to_s
    text   = url[prefix.length, 30]
    suffix = url[prefix.length + 30..-1]
    cutoff = url[prefix.length..-1].length > 30

    "<span class=\"invisible\">#{encode(prefix)}</span><span class=\"#{cutoff ? 'ellipsis' : ''}\">#{encode(text)}</span><span class=\"invisible\">#{encode(suffix)}</span>"
  end

  def hashtag_html(tag)
    "<a href=\"#{encode(tag_url(tag))}\" class=\"mention hashtag\" rel=\"tag\">#<span>#{encode(tag)}</span></a>"
  end

  def mention_html(account, with_domain: false)
    "<span class=\"h-card\"><a href=\"#{encode(ActivityPub::TagManager.instance.url_for(account))}\" class=\"u-url mention#{account.actor_type == 'Group' ? ' group' : ''}\">@<span>#{encode(with_domain ? account.pretty_acct : account.username)}</span></a></span>"
  end
end
