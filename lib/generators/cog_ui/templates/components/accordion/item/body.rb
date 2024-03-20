class <%= class_name %>::Item::Body < CogUiComponent
  erb_template <<~ERB
    <%%= tag.div do %>
      <%%= content %>
    <%% end %>
  ERB

  def initialize(**attributes)
    attributes[:data] = merge_data(attributes, data: { <%= file_name %>__item_target: "body" })

    super(**attributes)
  end
end