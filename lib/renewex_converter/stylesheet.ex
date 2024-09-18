defmodule RenewexConverter.Stylesheet do
  alias RenewexConverter.Stylesheet
  alias RenewexConverter.DocumentReader
  alias RenewexConverter.Conversion

  defstruct []

  @line_decoration_mapping Map.new([
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
                           ])

  @default_layer_style %{
    "opacity" => 1,
    "background_color" => "#70DB93",
    "border_color" => "black",
    "border_width" => "1"
  }

  # TODO implement default styling more consistent
  #
  # @default_text_style %{
  #   "opacity" => 1,
  #   "background_color" => "#70DB93",
  #   "border_color" => "black",
  #   "border_width" => "1",
  #   "border_dash_array" => nil
  # }
  #
  # @default_line_style %{
  #   "stroke_width" => "1",
  #   "stroke_color" => "black",
  #   "stroke_join" => "rect",
  #   "stroke_cap" => "rect",
  #   "stroke_dash_array" => nil,
  #   "smoothness" => 0
  # }

  @triangle_direction_mapping Map.new([
                                {0, "triangle-up"},
                                {1, "triangle-ne"},
                                {2, "triangle-right"},
                                {3, "triangle-se"},
                                {4, "triangle-down"},
                                {5, "triangle-sw"},
                                {6, "triangle-left"},
                                {7, "triangle-nw"}
                              ])

  def layer_style_for(
        %DocumentReader{conversion: %Conversion{} = conversion},
        :box,
        _fields,
        attrs
      ) do
    case attrs do
      nil ->
        @default_layer_style

      attrs ->
        %{
          "opacity" => Map.get(attrs, Conversion.key_for(conversion, :opacity), 1),
          "background_color" =>
            Conversion.convert_color(
              conversion,
              Map.get(attrs, Conversion.key_for(conversion, :fill_color), "#70DB93")
            ),
          "border_color" =>
            Conversion.convert_color(
              conversion,
              Map.get(attrs, Conversion.key_for(conversion, :frame_color), "black")
            ),
          "border_width" =>
            Conversion.convert_border_width(
              conversion,
              Map.get(attrs, Conversion.key_for(conversion, :line_width), 1)
            )
        }
    end
  end

  def layer_style_for(
        %DocumentReader{conversion: %Conversion{} = conversion},
        :text,
        _fields,
        attrs
      ) do
    case attrs do
      nil ->
        @default_layer_style

      attrs ->
        %{
          "opacity" => Map.get(attrs, Conversion.key_for(conversion, :opacity), 1),
          "background_color" =>
            Conversion.convert_color(
              conversion,
              Map.get(attrs, Conversion.key_for(conversion, :fill_color), "#70DB93")
            ),
          "border_color" =>
            Conversion.convert_color(
              conversion,
              Map.get(attrs, Conversion.key_for(conversion, :frame_color), "black")
            ),
          "border_width" =>
            Conversion.convert_border_width(
              conversion,
              Map.get(attrs, Conversion.key_for(conversion, :line_width), 1)
            ),
          "border_dash_array" =>
            Conversion.convert_line_style(
              conversion,
              Map.get(attrs, Conversion.key_for(conversion, :line_style))
            )
        }
    end
  end

  def layer_style_for(
        %DocumentReader{conversion: %Conversion{} = conversion} = reader,
        :edge,
        fields,
        attrs
      ) do
    case attrs do
      nil ->
        @default_layer_style

      attrs ->
        %{
          "opacity" => Map.get(attrs, Conversion.key_for(conversion, :opacity), 1),
          "background_color" =>
            Conversion.convert_color(
              conversion,
              Map.get(
                attrs,
                "FillColor"
              )
            ),
          "border_color" =>
            Conversion.convert_color(
              conversion,
              Map.get(attrs, Conversion.key_for(conversion, :frame_color), "black")
            ),
          "border_width" =>
            Conversion.convert_border_width(
              conversion,
              Map.get(attrs, Conversion.key_for(conversion, :line_width), 1)
            )
        }
    end
    |> Map.update("background_color", nil, fn _ ->
      line_decoration_background(
        reader,
        DocumentReader.resolve_ref(reader, Map.get(fields, :start_decoration)),
        DocumentReader.resolve_ref(reader, Map.get(fields, :end_decoration))
      )
    end)
  end

  def line_style(%DocumentReader{conversion: conversion} = reader, fields, attrs) do
    case attrs do
      nil ->
        %{
          "stroke_width" => "1",
          "stroke_color" => "black",
          "stroke_join" => "miter",
          "stroke_cap" => "butt",
          "stroke_dash_array" => nil,
          "smoothness" => Conversion.convert_smoothness(conversion, 0)
        }

      attrs ->
        %{
          "stroke_width" =>
            Conversion.convert_border_width(
              conversion,
              Map.get(attrs, Conversion.key_for(conversion, :line_width), 1)
            ),
          "stroke_color" =>
            Conversion.convert_color(
              conversion,
              Map.get(attrs, Conversion.key_for(conversion, :frame_color), "black")
            ),
          "stroke_join" => "miter",
          "stroke_cap" => "butt",
          "stroke_dash_array" =>
            Conversion.convert_line_style(
              conversion,
              Map.get(attrs, Conversion.key_for(conversion, :line_style))
            ),
          "smoothness" =>
            Conversion.convert_smoothness(
              conversion,
              Map.get(attrs, Conversion.key_for(conversion, :line_shape), 0)
            )
        }
    end
    |> Map.merge(line_tips(reader, fields))
  end

  def line_tips(%DocumentReader{conversion: conversion} = reader, fields) do
    %{
      "source_tip" =>
        Stylesheet.line_decoration(
          reader,
          DocumentReader.resolve_ref(reader, Map.get(fields, :start_decoration))
        ),
      "target_tip" =>
        Stylesheet.line_decoration(
          reader,
          DocumentReader.resolve_ref(reader, Map.get(fields, :end_decoration))
        ),
      "source_tip_symbol_shape_id" =>
        Conversion.symbol_id(
          conversion,
          Stylesheet.line_decoration(
            reader,
            DocumentReader.resolve_ref(reader, Map.get(fields, :start_decoration))
          )
        ),
      "target_tip_symbol_shape_id" =>
        Conversion.symbol_id(
          conversion,
          Stylesheet.line_decoration(
            reader,
            DocumentReader.resolve_ref(reader, Map.get(fields, :end_decoration))
          )
        )
    }
  end

  def text_style(%DocumentReader{conversion: conversion}, class_name, fields, attrs) do
    %{
      "underline" =>
        Conversion.convert_font_style(
          conversion,
          Map.get(fields, :fCurrentFontStyle, 0),
          :underlined
        ),
      "alignment" =>
        Conversion.convert_alignment(
          conversion,
          Map.get(attrs, Conversion.key_for(conversion, :text_alignment), 0)
        ),
      "font_size" => Map.get(fields, :fCurrentFontSize, 12),
      "font_family" =>
        Conversion.convert_font(
          conversion,
          Map.get(fields, :fCurrentFontName, "sans-serif")
        ),
      "bold" =>
        Conversion.convert_font_style(
          conversion,
          Map.get(fields, :fCurrentFontStyle, 0),
          :bold
        ),
      "italic" =>
        Conversion.convert_font_style(
          conversion,
          Map.get(fields, :fCurrentFontStyle, 0),
          :italic
        ),
      "text_color" =>
        Conversion.convert_color(
          conversion,
          Map.get(attrs, Conversion.key_for(conversion, :text_color), "black")
        ),
      "rich" => is_rich_text(class_name)
    }
  end

  def shape_for(
        %DocumentReader{grammar: grammar, conversion: conversion},
        class_name,
        fields,
        attrs
      ) do
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

      Renewex.Hierarchy.is_subtype_of(
        grammar,
        class_name,
        "de.renew.bpmn.figures.ActivityFigure"
      ) ->
        {case Map.get(fields, :type) do
           0 -> "bpmn-activity"
           1 -> "bpmn-activity-exchange"
         end,
         %{
           "rx" => 5,
           "ry" => 5
         }}

      Renewex.Hierarchy.is_subtype_of(
        grammar,
        class_name,
        "de.renew.bpmn.figures.GatewayFigure"
      ) ->
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
        {if Map.get(attrs, Conversion.key_for(conversion, :right_interface)) do
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

      Renewex.Hierarchy.is_subtype_of(
        grammar,
        class_name,
        "CH.ifa.draw.figures.RectangleFigure"
      ) ->
        {"rect", nil}

      true ->
        raise class_name
    end
  end

  def line_decoration(%DocumentReader{}, nil), do: nil

  def line_decoration(%DocumentReader{}, %Renewex.Storable{
        class_name: class_name
      }) do
    Map.get(@line_decoration_mapping, class_name)
  end

  def line_decoration(%DocumentReader{}, other), do: dbg(other)

  @fill_decorations [
    {%Renewex.Storable{
       class_name: "CH.ifa.draw.figures.ArrowTip",
       fields: %{filled: true}
     }, "black"}
  ]

  def line_decoration_background(
        %DocumentReader{},
        source,
        target
      ) do
    Enum.find_value(@fill_decorations, fn {pattern, color} ->
      if(matches_sub(pattern, source) or matches_sub(pattern, target), do: color)
    end)
  end

  def matches_sub(%{} = map, %{} = pattern) when is_struct(map) or is_struct(pattern) do
    matches_sub(Map.from_struct(map), Map.from_struct(pattern))
  end

  def matches_sub(%{} = map, %{} = pattern) do
    pattern
    |> Enum.reduce_while(true, fn {k, v}, acc ->
      if matches_sub(v, Map.get(map, k)) do
        {:cont, acc}
      else
        {:halt, false}
      end
    end)
  end

  def matches_sub(a, b), do: a == b

  defp is_rich_text(_), do: false

  @cyclic_path_shapes ["CH.ifa.draw.contrib.PolygonFigure"]

  def line_cyclicity(%DocumentReader{grammar: grammar}, class_name) do
    Enum.any?(@cyclic_path_shapes, &Renewex.Hierarchy.is_subtype_of(grammar, class_name, &1))
  end
end
