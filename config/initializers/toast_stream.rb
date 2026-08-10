# `turbo_stream.toast "Saved", kind: :success` — the server half of the toast
# host in shared/_toasts. See app/javascript/toast_stream.js for what the
# browser does with the tag this builds.
#
# Registered through Turbo's own extension point rather than by reopening the
# class, so it survives the gem loading whenever it likes. The block is
# instance_eval'd on the tag builder, which is why the kinds are a local rather
# than a constant: a constant written here would land on Object.
ActiveSupport.on_load :turbo_streams_tag_builder do
  # The message goes into the template as *escaped text*, not as markup.
  # `turbo_stream_action_tag` marks whatever it is handed as html_safe before
  # wrapping it, so escaping here is what stops a message built from a student's
  # own input carrying markup into the page.
  #
  # Everything else rides as an attribute, which `tag` escapes:
  #
  #   kind      one of info, success, warning, error. An unknown one raises:
  #             it would render as plain info and read as a styling bug rather
  #             than as the typo it is.
  #   title     an optional bold line above the message.
  #   duration  milliseconds. 0 keeps the toast until it is dismissed. Omitted
  #             leaves the controller's default alone — which is why it is not
  #             defaulted here.
  #   action    { label:, href:, method: } — one link out, e.g. an undo. A
  #             partial one is a mistake worth naming rather than a link that
  #             silently does not render.
  def toast(message, kind: :info, title: nil, duration: nil, action: nil)
    kinds = %i[ info success warning error ]
    unless kinds.include?(kind.to_sym)
      raise ArgumentError, "unknown toast kind #{kind.inspect}, expected one of #{kinds.join(", ")}"
    end

    if action && !(action[:label] && action[:href])
      raise ArgumentError, "a toast action needs both :label and :href, got #{action.inspect}"
    end

    turbo_stream_action_tag :toast, target: "toasts",
                            kind: kind, title: title, duration: duration,
                            "action-label": action&.dig(:label),
                            "action-href": action&.dig(:href),
                            "action-method": action&.dig(:method),
                            template: ERB::Util.html_escape(message)
  end
end
