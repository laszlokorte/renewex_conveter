defmodule RenewexConverter.DocumentReader do
  alias Renewex.Grammar
  alias RenewexConverter.Stylesheet
  alias RenewexConverter.LinkFinder
  alias RenewexConverter.HierarchyWalker
  alias RenewexConverter.Conversion
  alias RenewexConverter.DocumentReader

  defstruct [:grammar, :conversion, :stylesheet, :document, :id_map]

  def new(conversion, stylesheet, %Renewex.Document{refs: refs, version: version} = document) do
    %RenewexConverter.DocumentReader{
      grammar: Grammar.new(version),
      conversion: conversion,
      stylesheet: stylesheet,
      document: document,
      id_map:
        refs
        |> Enum.map(fn s -> {s, DocumentReader.generate_layer_id()} end)
        |> Enum.to_list()
    }
  end

  def read(
        %RenewexConverter.DocumentReader{
          document: %Renewex.Document{
            version: version,
            root: %Renewex.Storable{class_name: class_name}
          }
        } = reader
      ) do
    {unique_figs, hierarchy} =
      HierarchyWalker.find_unique_figures(reader)

    layers =
      for %{
            storable: storable,
            id: uid,
            zindex: zindex
          } <- unique_figs do
        read_layer(reader, uid, zindex, storable)
      end

    hyperlinks = LinkFinder.find_links(reader, unique_figs)

    {:ok,
     %RenewexConverter.LayeredDocument{
       version: version,
       kind: class_name,
       layers: layers,
       hierarchy: hierarchy,
       hyperlinks: hyperlinks
     }}
  end

  defp read_layer(
         %RenewexConverter.DocumentReader{} = reader,
         uid,
         z_index,
         %Renewex.Storable{
           class_name: class_name
         } = storable
       ) do
    hidden = read_hidden_flag(reader, storable)

    %RenewexConverter.Layer{
      id: uid,
      tag: class_name,
      z_index: z_index,
      hidden: hidden,
      original: storable,
      content: read_layer_content(reader, storable)
    }
  end

  def read_hidden_flag(%DocumentReader{conversion: conversion} = reader, storable) do
    attrs = read_layer_attrs(reader, storable)

    Conversion.convert(
      conversion,
      :visibility,
      Map.get(attrs, conversion |> Conversion.key_for(:visibility))
    )
  end

  def read_layer_attrs(_reader, layer) do
    with {{%Renewex.Storable{
             fields: fields
           }, _}, _} <- layer,
         %Renewex.Storable{fields: f} <- Map.get(fields, :attributes) do
      f.attributes |> Enum.into(%{}, fn {key, _type, value} -> {key, value} end)
    else
      _ -> %{}
    end
  end

  def read_layer_content(
        %DocumentReader{conversion: conversion} = reader,
        %Renewex.Storable{
          class_name: class_name,
          fields: %{x: x, y: y, w: w, h: h} = fields
        } = storable
      ) do
    attrs = read_layer_attrs(reader, storable)
    layer_style = Stylesheet.layer_style_for(reader, :box, fields, attrs)

    {shape_name, shape_attributes} =
      Stylesheet.shape_for(reader, class_name, fields, attrs)

    %{
      "box" => %{
        "position_x" => x,
        "position_y" => y,
        "width" => w,
        "height" => h,
        "symbol_shape_attributes" => shape_attributes,
        "symbol_shape_id" => Conversion.symbol_id(conversion, shape_name)
      },
      "style" => layer_style
    }
  end

  def read_layer_content(
        reader,
        %Renewex.Storable{
          class_name: class_name,
          fields: %{text: body, fOriginX: x, fOriginY: y} = fields
        } = storable
      ) do
    attrs = read_layer_attrs(reader, storable)
    layer_style = Stylesheet.layer_style_for(reader, :text, fields, attrs)
    text_style = Stylesheet.text_style(reader, class_name, fields, attrs)

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

  def read_layer_content(
        %DocumentReader{} = reader,
        %Renewex.Storable{
          class_name: class_name,
          fields: %{points: [_, _ | _] = points} = fields
        } = storable
      ) do
    attrs = read_layer_attrs(reader, storable)
    %{x: start_x, y: start_y} = hd(points) |> Enum.into(%{})
    %{x: end_x, y: end_y} = List.last(points) |> Enum.into(%{})

    layer_style =
      Stylesheet.layer_style_for(reader, :edge, fields, attrs)

    line_style = Stylesheet.line_style(reader, fields, attrs)

    %{
      "style" => layer_style,
      "edge" => %{
        "source_x" => start_x,
        "source_y" => start_y,
        "target_x" => end_x,
        "target_y" => end_y,
        "cyclic" => Stylesheet.line_cyclicity(reader, class_name),
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
        "style" => line_style
      }
    }
  end

  def read_layer_content(_reader, %Renewex.Storable{}) do
    nil
  end

  def resolve_ref(%DocumentReader{document: %Renewex.Document{refs: refs}}, {:ref, r}),
    do: Enum.at(refs, r)

  def resolve_ref(_, nil), do: nil
  def resolve_ref(_, noref), do: noref

  def generate_layer_id() do
    UUID.uuid4()
  end
end
