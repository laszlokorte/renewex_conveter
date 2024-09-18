defmodule RenewexConverter.DocumentReader do
  alias RenewexConverter.LinkFinder
  alias RenewexConverter.HierarchyWalker
  alias RenewexConverter.Config
  alias RenewexConverter.Conversion
  alias RenewexConverter.DocumentReader

  defstruct [:conversion, :stylesheet, :document, :id_map]

  def new(conversion, stylesheet, %Renewex.Document{refs: refs} = document) do
    %RenewexConverter.DocumentReader{
      conversion: conversion,
      stylesheet: stylesheet,
      document: document,
      id_map:
        refs
        |> Enum.map(fn s -> {s, Conversion.generate_layer_id(conversion)} end)
        |> Enum.to_list()
    }
  end

  def read(%RenewexConverter.Config{} = config, %Renewex.Document{
        version: version,
        root: root,
        refs: refs
      }) do
    with %Renewex.Storable{class_name: class_name, fields: %{figures: root_figures}} <-
           root do
      refs_with_ids =
        refs
        |> Enum.map(fn s -> {s, Config.generate_layer_id(config)} end)
        |> Enum.to_list()

      {unique_figs, hierarchy} =
        HierarchyWalker.find_unique_figures(config, root_figures, refs_with_ids)

      layers =
        for layer <- unique_figs do
          read_layer(config, layer, refs)
        end

      hyperlinks = LinkFinder.find_links(config, unique_figs, refs_with_ids)

      {:ok,
       %RenewexConverter.LayeredDocument{
         version: version,
         kind: class_name,
         layers: layers,
         hierarchy: hierarchy,
         hyperlinks: hyperlinks
       }}
    end
  end

  defp read_layer(config, layer, refs) do
    attrs =
      with {{%Renewex.Storable{
               fields: fields
             }, _}, _} <- layer,
           %Renewex.Storable{fields: f} <- Map.get(fields, :attributes) do
        f.attributes |> Enum.into(%{}, fn {key, _type, value} -> {key, value} end)
      else
        _ -> nil
      end

    hidden = Config.convert_attrs_hidden(config, attrs)

    with {{%Renewex.Storable{
             class_name: class_name
           } = storable, uuid}, z_index} <- layer do
      %RenewexConverter.Layer{
        id: uuid,
        tag: class_name,
        z_index: z_index,
        hidden: hidden,
        original: storable,
        content: read_layer_content(config, refs, attrs, storable)
      }
    end
  end

  def read_layer_content(config, attrs, %Renewex.Storable{
        class_name: class_name,
        fields: %{x: x, y: y, w: w, h: h} = fields
      }) do
    layer_style = Config.layer_style_for(config, :box, attrs)

    {shape_name, shape_attributes} =
      Config.convert_shape(config, class_name, fields, attrs)

    %{
      "box" => %{
        "position_x" => x,
        "position_y" => y,
        "width" => w,
        "height" => h,
        "symbol_shape_attributes" => shape_attributes,
        "symbol_shape_id" => Config.symbol_id(config, shape_name)
      },
      "style" => layer_style
    }
  end

  def read_layer_content(config, _refs, attrs, %Renewex.Storable{
        class_name: class_name,
        fields: %{text: body, fOriginX: x, fOriginY: y} = fields
      }) do
    layer_style = Config.layer_style_for(config, :text, attrs)
    text_style = Config.text_style(config, class_name, fields, attrs)

    %{
      "style" => layer_style,
      "text" => %{
        "position_x" => x,
        "position_y" => y,
        "body" => if(is_nil(body), do: "", else: body),
        "style" => text_style
      }
    }
  end

  def read_layer_content(config, refs, attrs, %Renewex.Storable{
        class_name: class_name,
        fields: %{points: [_, _ | _] = points} = fields
      }) do
    %{x: start_x, y: start_y} = hd(points) |> Enum.into(%{})
    %{x: end_x, y: end_y} = List.last(points) |> Enum.into(%{})

    layer_style =
      Config.layer_style_for(config, :edge, attrs)
      |> Map.update("background_color", nil, fn _ ->
        Config.convert_line_decoration_background(
          config,
          resolve_ref(refs, Map.get(fields, :start_decoration)),
          resolve_ref(refs, Map.get(fields, :end_decoration))
        )
      end)

    line_style = Config.line_style(config, attrs)

    tips = %{
      "source_tip" =>
        Config.convert_line_decoration(
          config,
          resolve_ref(refs, Map.get(fields, :start_decoration))
        ),
      "target_tip" =>
        Config.convert_line_decoration(
          config,
          resolve_ref(refs, Map.get(fields, :end_decoration))
        ),
      "source_tip_symbol_shape_id" =>
        config
        |> Config.symbol_id(
          Config.convert_line_decoration(
            config,
            resolve_ref(refs, Map.get(fields, :start_decoration))
          )
        ),
      "target_tip_symbol_shape_id" =>
        config
        |> Config.symbol_id(
          Config.convert_line_decoration(
            config,
            resolve_ref(refs, Map.get(fields, :end_decoration))
          )
        )
    }

    %{
      "style" => layer_style,
      "edge" => %{
        "source_x" => start_x,
        "source_y" => start_y,
        "target_x" => end_x,
        "target_y" => end_y,
        "cyclic" => Config.convert_line_cyclicity(config, class_name),
        "waypoints" =>
          points
          |> Enum.drop(1)
          |> Enum.drop(-1)
          |> Enum.with_index()
          |> Enum.map(fn {p, index} ->
            %{
              "sort" => index,
              "position_x" => p[:x],
              "position_y" => p[:y]
            }
          end),
        "style" => Map.merge(line_style, tips)
      }
    }
  end

  def read_layer_content(_config, _refs, _attrs, %Renewex.Storable{}) do
    nil
  end

  def resolve_ref(%DocumentReader{document: %Renewex.Document{refs: refs}}, {:ref, r}),
    do: Enum.at(refs, r)

  def resolve_ref(refs, {:ref, r}), do: Enum.at(refs, r)
  def resolve_ref(_, nil), do: nil
  def resolve_ref(_, noref), do: noref
end
