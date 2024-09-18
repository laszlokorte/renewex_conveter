defmodule RenewexConverter.Conversion do
  alias RenewexConverter.Conversion

  defstruct []

  @transparent_color_marker_rgba {:rgba, 255, 199, 158, 255}
  @transparent_color_marker_rgb {:rgb, 255, 199, 158, 255}
  @color_alpha_max 255.0

  @transparent_color_marker_web "transparent"

  @font_style_bitmaks Map.new([{:bold, 1}, {:italic, 2}, {:underlined, 4}])

  @text_alignments Map.new([{0, :left}, {1, :center}, {2, :right}])
  @text_alignment_default :left

  @font_family_mapping Map.new([{"SansSerif", "sans-serif"}, {"Serif", "serif"}])

  @smoothness_mapping Map.new([{0, :linear}, {1, :autobezier}])

  @reorder_children_of [
    "de.renew.netcomponents.NetComponentFigure"
  ]

  def key_for(%Conversion{}, :fill_color), do: "FillColor"
  def key_for(%Conversion{}, :frame_color), do: "FrameColor"
  def key_for(%Conversion{}, :line_shape), do: "LineShape"
  def key_for(%Conversion{}, :line_style), do: "LineStyle"
  def key_for(%Conversion{}, :line_width), do: "LineWidth"
  def key_for(%Conversion{}, :opacity), do: "Opacity"
  def key_for(%Conversion{}, :text_alignment), do: "TextAlignment"
  def key_for(%Conversion{}, :text_color), do: "TextColor"
  def key_for(%Conversion{}, :right_interface), do: "RightInterface"
  def key_for(%Conversion{}, :visibility), do: "Visibility"

  def convert(%Conversion{}, :visibility, value) when is_boolean(value), do: not value
  def convert(%Conversion{}, :visibility, _), do: not false
  def convert_color(%Conversion{}, m) when is_binary(m), do: m

  def convert_color(%Conversion{}, @transparent_color_marker_rgba),
    do: @transparent_color_marker_web

  def convert_color(%Conversion{}, @transparent_color_marker_rgb),
    do: @transparent_color_marker_web

  def convert_color(%Conversion{}, {:rgba, r, g, b, a}) when is_integer(a),
    do: "rgba(#{r},#{g},#{b},#{a / @color_alpha_max})"

  def convert_color(%Conversion{}, {:rgba, r, g, b, a}) when is_float(a) and a <= 1.0,
    do: "rgba(#{r},#{g},#{b},#{a})"

  def convert_color(%Conversion{}, {:rgba, r, g, b, a}) when is_float(a),
    do: "rgba(#{r},#{g},#{b},1.0)"

  def convert_color(%Conversion{}, {:rgb, r, g, b}), do: "rgb(#{r},#{g},#{b})"
  def convert_color(%Conversion{}, nil), do: @transparent_color_marker_web

  def convert_alignment(%Conversion{}, alignment_int),
    do: Map.get(@text_alignments, alignment_int, @text_alignment_default)

  def convert_font_style(%Conversion{}, bitmask, style),
    do: Bitwise.band(bitmask, @font_style_bitmaks[style]) == @font_style_bitmaks[style]

  def convert_font(%Conversion{}, font_name) when is_binary(font_name),
    do: Map.get(@font_family_mapping, font_name, font_name)

  def convert_line_style(%Conversion{}, gap) when is_integer(gap), do: Integer.to_string(gap)
  def convert_line_style(%Conversion{}, dasharray) when is_binary(dasharray), do: dasharray
  def convert_line_style(%Conversion{}, nil), do: nil

  def convert_border_width(%Conversion{}, width) when is_integer(width),
    do: Integer.to_string(width)

  def convert_border_width(%Conversion{}, width) when is_binary(width), do: width
  def convert_border_width(%Conversion{}, nil), do: nil

  def convert_smoothness(%Conversion{}, smoothness), do: Map.get(@smoothness_mapping, smoothness)

  def convert_visibility_to_hidden(%Conversion{}, visible) when is_boolean(visible),
    do: not visible

  def convert_visibility_to_hidden(%Conversion{}, nil), do: false
  def convert_visibility_to_hidden(%Conversion{}, _), do: false

  @reorder_children_of [
    "de.renew.netcomponents.NetComponentFigure"
  ]
  def fix_hierarchy_order(
        %RenewexConverter.DocumentReader{
          grammar: grammar
        },
        refs,
        class_name
      ) do
    if(
      Enum.any?(@reorder_children_of, &Renewex.Hierarchy.is_subtype_of(grammar, class_name, &1))
    ) do
      refs |> Enum.sort_by(fn {:ref, ref_index} -> ref_index end)
    else
      refs
    end
  end
end
