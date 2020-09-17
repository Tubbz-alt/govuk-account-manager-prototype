module ErrorItemsHelper
  def error_items(field)
    if flash[:validation] && flash[:validation].select { |item| item[:field] == field }.any?
      sanitize(flash[:validation]
        .select { |key| key.to_s.match(field) }
        .map { |error| error[:text] }.uniq
        .join("<br>"))
    end
  end

  def devise_error_items(field)
    return nil unless resource

    all_errors = resource.errors.messages.map do |id, errors|
      errors.map do |error|
        { field: id, error: error }
      end
    end

    resource_errors = all_errors.flatten.select { |item| item[:field] == field }

    if resource_errors.any?
      resource_errors
        .pluck(:error)
        .join("<br>")
    end
  end

  PREVIOUS_URL_IGNORE_LIST = %w[
    /
    /account
  ].freeze

  PREVIOUS_URL_IGNORE_PATH_STARTS_WITH = %w[
    /oauth/
  ].freeze

  def previous_url_is_on_ignore_list(previous_url)
    PREVIOUS_URL_IGNORE_LIST.include?(previous_url) || include_starts_with?(previous_url)
  end

  def include_starts_with?(previous_url)
    PREVIOUS_URL_IGNORE_PATH_STARTS_WITH.any? { |path| previous_url.start_with?(path) }
  end

  def remove_flash_alert
    flash[:alert] = nil
  end
end
