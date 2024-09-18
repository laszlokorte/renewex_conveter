defmodule RenewexConverter.Config do
  alias RenewexConverter.Config

  @font_style_bitmaks [
                        {:bold, 1},
                        {:italic, 2},
                        {:underlined, 4}
                      ]
                      |> Map.new()

  @text_alignments [
                     {0, :left},
                     {1, :center},
                     {2, :right}
                   ]
                   |> Map.new()
  @text_alignment_default :left

  @transparent_color_marker_rgba {:rgba, 255, 199, 158, 255}
  @transparent_color_marker_rgb {:rgb, 255, 199, 158, 255}
  @color_alpha_max 255.0

  @transparent_color_marker_web "transparent"

  @font_family_mapping [
                         {"SansSerif", "sans-serif"},
                         {"Serif", "serif"}
                       ]
                       |> Map.new()

  @smoothness_mapping [
                        {0, :linear},
                        {1, :autobezier}
                      ]
                      |> Map.new()

  @line_decoration_mapping [
                             {"de.renew.gui.AssocArrowTip", "arrow-tip-normal"},
                             {"de.renew.diagram.AssocArrowTip", "arrow-tip-normal"},
                             {"de.renew.gui.CompositionArrowTip", "arrow-tip-lines"},
                             {"de.renew.gui.IsaArrowTip", "arrow-tip-triangle"},
                             {"de.renew.gui.fs.IsaArrowTip", "arrow-tip-triangle"},
                             {"fs.IsaArrowTip", "arrow-tip-triangle"},
                             {"de.renew.gui.fs.AssocArrowTip", "arrow-tip-normal"},
                             {"de.renew.diagram.SynchronousMessageArrowTip", "arrow-tip-lines"},
                             {"de.renew.gui.CircleDecoration", "arrow-tip-circle"},
                             {"CH.ifa.draw.figures.ArrowTip", "arrow-tip-normal"},
                             {"de.renew.gui.DoubleArrowTip", "arrow-tip-double"}
                           ]
                           |> Map.new()

  @attr_visibility "Visibility"

  @cyclic_path_shapes ["CH.ifa.draw.contrib.PolygonFigure"]

  @triangle_direction_mapping [
                                {0, "triangle-up"},
                                {1, "triangle-ne"},
                                {2, "triangle-right"},
                                {3, "triangle-se"},
                                {4, "triangle-down"},
                                {5, "triangle-sw"},
                                {6, "triangle-left"},
                                {7, "triangle-nw"}
                              ]
                              |> Map.new()

  @reorder_children_of [
    "de.renew.netcomponents.NetComponentFigure"
  ]

  @fill_decoration [
    {%Renewex.Storable{
       class_name: "CH.ifa.draw.figures.ArrowTip",
       fields: %{filled: true}
     }, "black"}
  ]

  @default_layer_style %{
    "opacity" => 1,
    "background_color" => "#70DB93",
    "border_color" => "black",
    "border_width" => "1"
  }

  @default_text_style %{
    "opacity" => 1,
    "background_color" => "#70DB93",
    "border_color" => "black",
    "border_width" => "1",
    "border_dash_array" => nil
  }

  @default_edge_style %{
    "stroke_width" => "1",
    "stroke_color" => "black",
    "stroke_join" => "rect",
    "stroke_cap" => "rect",
    "stroke_dash_array" => nil,
    "smoothness" => 0
  }

  defstruct [:grammar]

  def new(grammar) do
    %RenewexConverter.Config{grammar: grammar}
  end

  def convert_color(%Config{}, m) when is_binary(m), do: m
  def convert_color(%Config{}, @transparent_color_marker_rgba), do: @transparent_color_marker_web
  def convert_color(%Config{}, @transparent_color_marker_rgb), do: @transparent_color_marker_web

  def convert_color(%Config{}, {:rgba, r, g, b, a}) when is_integer(a),
    do: "rgba(#{r},#{g},#{b},#{a / @color_alpha_max})"

  def convert_color(%Config{}, {:rgba, r, g, b, a}) when is_float(a) and a <= 1.0,
    do: "rgba(#{r},#{g},#{b},#{a})"

  def convert_color(%Config{}, {:rgba, r, g, b, a}) when is_float(a),
    do: "rgba(#{r},#{g},#{b},1.0)"

  def convert_color(%Config{}, {:rgb, r, g, b}), do: "rgb(#{r},#{g},#{b})"
  def convert_color(%Config{}, nil), do: @transparent_color_marker_web

  def convert_alignment(%Config{}, alignment_int),
    do: Map.get(@text_alignments, alignment_int, @text_alignment_default)

  def convert_font_style(%Config{}, bitmask, style),
    do: Bitwise.band(bitmask, @font_style_bitmaks[style]) == @font_style_bitmaks[style]

  def convert_font(%Config{}, font_name) when is_binary(font_name),
    do: Map.get(@font_family_mapping, font_name, font_name)

  def convert_line_style(%Config{}, gap) when is_integer(gap), do: Integer.to_string(gap)
  def convert_line_style(%Config{}, dasharray) when is_binary(dasharray), do: dasharray
  def convert_line_style(%Config{}, nil), do: nil

  def convert_border_width(%Config{}, width) when is_integer(width), do: Integer.to_string(width)
  def convert_border_width(%Config{}, width) when is_binary(width), do: width
  def convert_border_width(%Config{}, nil), do: nil

  def convert_smoothness(%Config{}, smoothness), do: Map.get(@smoothness_mapping, smoothness)

  def convert_line_decoration(%Config{}, nil), do: nil

  def convert_line_decoration(%Config{}, %Renewex.Storable{
        class_name: class_name
      }) do
    Map.get(@line_decoration_mapping, class_name)
  end

  def convert_line_decoration(%Config{}, other), do: dbg(other)

  def convert_line_decoration_background(
        %Config{},
        source,
        target
      ) do
    Enum.find_value(@fill_decoration, fn {pattern, color} ->
      if(matches_sub(pattern, source) or matches_sub(pattern, target), do: color)
    end)
  end

  def matches_sub(%{} = map, %{} = pattern) when is_struct(map) or is_struct(pattern) do
    matches_sub(Map.from_struct(map), Map.from_struct(pattern))
  end

  def matches_sub(%{} = map, %{} = pattern) do
    pattern
    |> Enum.reduce_while(true, fn {k, v}, acc ->
      # This statement checks if the key from map_a exists in map_b. if the key exists, also checks the 
      # value of the keys. If it is true, iteration is continued, otherwise it is halted and it will return false
      if matches_sub(v, Map.get(map, k)) do
        {:cont, acc}
      else
        {:halt, false}
      end
    end)
  end

  def matches_sub(a, b), do: a == b

  def convert_attrs_hidden(%Config{}, nil), do: false

  def convert_attrs_hidden(%Config{} = conf, %{} = attrs),
    do: convert_visibility_to_hidden(conf, Map.get(attrs, @attr_visibility))

  def convert_visibility_to_hidden(%Config{}, visible) when is_boolean(visible), do: not visible
  def convert_visibility_to_hidden(%Config{}, nil), do: false
  def convert_visibility_to_hidden(%Config{}, _), do: false

  def convert_line_cyclicity(%Config{grammar: grammar}, class_name) do
    Enum.any?(@cyclic_path_shapes, &Renewex.Hierarchy.is_subtype_of(grammar, class_name, &1))
  end

  def is_rich_text(%Config{grammar: grammar}, class_name),
    do: Renewex.Hierarchy.is_subtype_of(grammar, class_name, "de.renew.gui.fs.ConceptFigure")

  def convert_shape(%Config{grammar: grammar}, class_name, fields, attrs) do
    cond do
      Renewex.Hierarchy.is_subtype_of(
        grammar,
        class_name,
        "de.renew.bpmn.figures.DataStoreFigure"
      ) ->
        {"database", nil}

      Renewex.Hierarchy.is_subtype_of(grammar, class_name, "de.renew.bpmn.figures.DataFigure") ->
        {case Map.get(fields, :type) do
           0 -> "rect-fold-paper-proportional"
           1 -> "rect-fold-paper-proportional-arrow-right"
           2 -> "rect-fold-paper-proportional-arrow-right-black"
           3 -> "rect-fold-paper-proportional-striped"
         end, nil}

      Renewex.Hierarchy.is_subtype_of(grammar, class_name, "de.renew.bpmn.figures.ActivityFigure") ->
        {case Map.get(fields, :type) do
           0 -> "bpmn-activity"
           1 -> "bpmn-activity-exchange"
         end,
         %{
           "rx" => 5,
           "ry" => 5
         }}

      Renewex.Hierarchy.is_subtype_of(grammar, class_name, "de.renew.bpmn.figures.GatewayFigure") ->
        {case Map.get(fields, :type) do
           0 -> "bpmn-gateway"
           1 -> "bpmn-gateway-xor"
           2 -> "bpmn-gateway-and"
         end, nil}

      Renewex.Hierarchy.is_subtype_of(grammar, class_name, "de.renew.bpmn.figures.EventFigure") ->
        {case {Map.get(fields, :position), Map.get(fields, :type), Map.get(fields, :throwing)} do
           {0, 0, false} -> "bpmn-start-standard"
           {0, 0, true} -> "bpmn-start-standard-throwing"
           {0, 1, false} -> "bpmn-start-message"
           {0, 1, true} -> "bpmn-start-message-throwing"
           {0, 2, false} -> "bpmn-start-terminate"
           {0, 2, true} -> "bpmn-start-terminate-throwing"
           {1, 0, false} -> "bpmn-interm-standard"
           {1, 0, true} -> "bpmn-interm-standard-throwing"
           {1, 1, false} -> "bpmn-interm-message"
           {1, 1, true} -> "bpmn-interm-message-throwing"
           {1, 2, false} -> "bpmn-interm-terminate"
           {1, 2, true} -> "bpmn-interm-terminate-throwing"
           {2, 0, false} -> "bpmn-end-standard"
           {2, 0, true} -> "bpmn-end-standard-throwing"
           {2, 1, false} -> "bpmn-end-message"
           {2, 1, true} -> "bpmn-end-message-throwing"
           {2, 2, false} -> "bpmn-end-terminate"
           {2, 2, true} -> "bpmn-end-terminate-throwing"
         end, nil}

      Renewex.Hierarchy.is_subtype_of(grammar, class_name, "de.renew.bpmn.figures.PoolFigure") ->
        {"bpmn-pool", nil}

      Renewex.Hierarchy.is_subtype_of(
        grammar,
        class_name,
        "de.renew.diagram.RoleDescriptorFigure"
      ) ->
        {"rect", nil}

      Renewex.Hierarchy.is_subtype_of(grammar, class_name, "de.renew.diagram.VJoinFigure") ->
        # fields.decoration.class_name == de.renew.diagram.XORDecoration
        # fields.decoration.class_name == de.renew.diagram.ANDDecoration
        {"bar-horizontal-black-diamond-quad", nil}

      Renewex.Hierarchy.is_subtype_of(grammar, class_name, "de.renew.diagram.VSplitFigure") ->
        {"bar-horizontal-black-diamond-quad", nil}

      Renewex.Hierarchy.is_subtype_of(grammar, class_name, "de.renew.diagram.HSplitFigure") ->
        {"bar-vertical-black-diamond-quad", nil}

      Renewex.Hierarchy.is_subtype_of(grammar, class_name, "de.renew.diagram.TaskFigure") ->
        {"bar-vertical-black-diamond-quad", nil}

      Renewex.Hierarchy.is_subtype_of(grammar, class_name, "fs.PartitionFigure") ->
        {"rect", nil}

      Renewex.Hierarchy.is_subtype_of(grammar, class_name, "CH.ifa.draw.figures.ImageFigure") ->
        {"rect", nil}

      Renewex.Hierarchy.is_subtype_of(
        grammar,
        class_name,
        "de.renew.interfacenets.datatypes.InterfaceBoxFigure"
      ) ->
        {"bracket-both-outer", nil}

      Renewex.Hierarchy.is_subtype_of(
        grammar,
        class_name,
        "de.renew.interfacenets.datatypes.InterfaceFigure"
      ) ->
        {if Map.get(attrs, "RightInterface") do
           "bracket-right-outer"
         else
           "bracket-left-outer"
         end, nil}

      Renewex.Hierarchy.is_subtype_of(grammar, class_name, "CH.ifa.draw.contrib.TriangleFigure") ->
        {Map.get(@triangle_direction_mapping, Map.get(fields, :rotation)), nil}

      Renewex.Hierarchy.is_subtype_of(grammar, class_name, "CH.ifa.draw.contrib.DiamondFigure") ->
        {"diamond", nil}

      Renewex.Hierarchy.is_subtype_of(grammar, class_name, "de.renew.gui.VirtualPlaceFigure") ->
        {"ellipse-double-in", nil}

      Renewex.Hierarchy.is_subtype_of(grammar, class_name, "CH.ifa.draw.figures.EllipseFigure") ->
        {"ellipse", nil}

      Renewex.Hierarchy.is_subtype_of(grammar, class_name, "CH.ifa.draw.figures.PieFigure") ->
        # "pie:#{Map.get(fields, :start_angle)}:#{Map.get(fields, :end_angle)}"
        {"pie",
         %{
           "start_angle" => Map.get(fields, :start_angle),
           "end_angle" => Map.get(fields, :end_angle)
         }}

      Renewex.Hierarchy.is_subtype_of(
        grammar,
        class_name,
        "CH.ifa.draw.figures.RoundRectangleFigure"
      ) ->
        # "roundrect:#{Map.get(fields, :arc_width, 0)}:#{Map.get(fields, :arc_height, 0)}"
        {"rect-round",
         %{
           "rx" => Map.get(fields, :arc_width, 0),
           "ry" => Map.get(fields, :arc_height, 0)
         }}

      Renewex.Hierarchy.is_subtype_of(grammar, class_name, "CH.ifa.draw.figures.RectangleFigure") ->
        {"rect", nil}

      true ->
        raise class_name
    end
  end

  def symbol_id(config, symbol_name) do
  end

  def fix_hierarchy_order(%Config{grammar: grammar}, refs, class_name) do
    if(
      Enum.any?(@reorder_children_of, &Renewex.Hierarchy.is_subtype_of(grammar, class_name, &1))
    ) do
      refs |> Enum.sort_by(fn {:ref, ref_index} -> ref_index end)
    else
      refs
    end
  end

  def generate_layer_id(%Config{}) do
    UUID.uuid4()
  end

  def layer_style_for(%Config{} = config, :box, attrs) do
    case attrs do
      nil ->
        nil

        %{
          "opacity" => 1,
          "background_color" => "#70DB93",
          "border_color" => "black",
          "border_width" => "1"
        }

      attrs ->
        %{
          "opacity" => Map.get(attrs, "Opacity", 1),
          "background_color" =>
            Config.convert_color(config, Map.get(attrs, "FillColor", "#70DB93")),
          "border_color" => Config.convert_color(config, Map.get(attrs, "FrameColor", "black")),
          "border_width" => Config.convert_border_width(config, Map.get(attrs, "LineWidth", 1))
        }
    end
  end

  def layer_style_for(%Config{} = config, :text, attrs) do
    case attrs do
      nil ->
        nil

      # %{
      #   "opacity" => 1,
      #   "background_color" => "#70DB93",
      #   "border_color" => "black",
      #   "border_width" => "1",
      #   "border_dash_array" => nil
      # }

      attrs ->
        %{
          "opacity" => Map.get(attrs, "Opacity", 1),
          "background_color" =>
            Config.convert_color(config, Map.get(attrs, "FillColor", "#70DB93")),
          "border_color" => Config.convert_color(config, Map.get(attrs, "FrameColor", "black")),
          "border_width" => Config.convert_border_width(config, Map.get(attrs, "LineWidth", 1)),
          "border_dash_array" => Config.convert_line_style(config, Map.get(attrs, "LineStyle"))
        }
    end
  end

  def layer_style_for(%Config{} = config, :edge, attrs) do
    case attrs do
      nil ->
        nil

      # %{
      #   "opacity" => 1,
      #   "background_color" => "#70DB93",
      #   "border_color" => "black",
      #   "border_width" => "1"
      # }

      attrs ->
        %{
          "opacity" => Map.get(attrs, "Opacity", 1),
          "background_color" =>
            Config.convert_color(
              config,
              Map.get(
                attrs,
                "FillColor"
              )
            ),
          "border_color" => Config.convert_color(config, Map.get(attrs, "FrameColor", "black")),
          "border_width" => Config.convert_border_width(config, Map.get(attrs, "LineWidth", 1))
        }
    end
  end

  def line_style(config, attrs) do
    case attrs do
      nil ->
        %{
          "stroke_width" => "1",
          "stroke_color" => "black",
          "stroke_join" => "rect",
          "stroke_cap" => "rect",
          "stroke_dash_array" => nil,
          "smoothness" => Config.convert_smoothness(config, 0)
        }

      attrs ->
        %{
          "stroke_width" => Config.convert_border_width(config, Map.get(attrs, "LineWidth", 1)),
          "stroke_color" => Config.convert_color(config, Map.get(attrs, "FrameColor", "black")),
          "stroke_join" => "rect",
          "stroke_cap" => "rect",
          "stroke_dash_array" => Config.convert_line_style(config, Map.get(attrs, "LineStyle")),
          "smoothness" => Config.convert_smoothness(config, Map.get(attrs, "LineShape", 0))
        }
    end
  end

  def text_style(config, class_name, fields, attrs) do
    %{
      "underline" =>
        Config.convert_font_style(
          config,
          Map.get(fields, :fCurrentFontStyle, 0),
          :underlined
        ),
      "alignment" => Config.convert_alignment(config, Map.get(attrs, "TextAlignment", 0)),
      "font_size" => Map.get(fields, :fCurrentFontSize, 12),
      "font_family" =>
        Config.convert_font(
          config,
          Map.get(fields, :fCurrentFontName, "sans-serif")
        ),
      "bold" =>
        Config.convert_font_style(
          config,
          Map.get(fields, :fCurrentFontStyle, 0),
          :bold
        ),
      "italic" =>
        Config.convert_font_style(
          config,
          Map.get(fields, :fCurrentFontStyle, 0),
          :italic
        ),
      "text_color" => Config.convert_color(config, Map.get(attrs, "TextColor", "black")),
      "rich" => Config.is_rich_text(config, class_name)
    }
  end
end
