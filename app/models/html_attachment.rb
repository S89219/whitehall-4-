class HtmlAttachment < Attachment
  extend FriendlyId

  include HasContentId

  has_one :govspeak_content,
          autosave: true,
          inverse_of: :html_attachment,
          dependent: :destroy

  before_validation :clear_slug_if_non_english_locale

  validates :govspeak_content, presence: true

  accepts_nested_attributes_for :govspeak_content
  delegate :body,
           :body_html,
           :headers_html,
           to: :govspeak_content,
           allow_nil: true,
           prefix: true

  def rendering_app
    Whitehall::RenderingApp::GOVERNMENT_FRONTEND
  end

  delegate :manually_numbered_headings?, to: :govspeak_content

  def accessible?
    true
  end

  def html?
    true
  end

  def pdf?
    false
  end

  def csv?
    false
  end

  # Is in OpenDocument format? (see https://en.wikipedia.org/wiki/OpenDocument)
  def opendocument?
    false
  end

  def content_type
    "text/html"
  end

  def name_for_link
    "HTML attachment"
  end

  def url(options = {})
    preview = options.delete(:preview)
    full_url = options.delete(:full_url)

    if preview
      options[:preview] = id
      options[:host] = URI(Plek.new.external_url_for("draft-origin")).host
    else
      options[:host] = URI(Plek.new.website_root).host
    end

    type = attachable.path_name
    path_or_url = full_url ? "url" : "path"
    path_helper = "#{type}_html_attachment_#{path_or_url}"

    # This depends on the rails url helpers to construct a url based on config/routes.rb:
    # composed of document type, slug for the parent document, and identifier for the attachment;
    # for non-english attachments the identifier is the content_id, for english
    # attachments it is self i.e. the slug
    identifier = sluggable_locale? ? self : content_id
    Whitehall.url_maker.public_send(path_helper, attachable.slug, identifier, options)
  end

  def should_generate_new_friendly_id?
    return false unless sluggable_locale?

    slug.nil? || attachable.nil? || safely_resluggable?
  end

  def deep_clone
    super.tap do |clone|
      clone.slug = slug
      clone.content_id = content_id
      clone.govspeak_content = govspeak_content.dup
    end
  end

  def readable_type
    "HTML"
  end

  def translated_locales
    [locale || I18n.default_locale.to_s]
  end

private

  def sluggable_locale?
    locale.blank? || (locale == "en")
  end

  def sluggable_string
    sluggable_locale? ? title : nil
  end

  def clear_slug_if_non_english_locale
    if locale_changed? && !sluggable_locale?
      self.slug = nil
    end
  end
end
