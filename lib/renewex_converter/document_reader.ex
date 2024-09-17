defmodule RenewexConverter.DocumentReader do
  alias RenewexConverter.LinkFinder
  alias RenewexConverter.HierarchyWalker
  alias RenewexConverter.Config

  def read(%RenewexConverter.Config{} = config, %Renewex.Document{
        version: version,
        root: root,
        refs: refs
      }) do
    with %Renewex.Storable{class_name: class_name, fields: %{figures: root_figures}} <-
           root do
      symbol_ids = Map.new()

      refs_with_ids =
        refs
        |> Enum.map(fn s -> {s, Config.generate_layer_id(config)} end)
        |> Enum.to_list()

      {unique_figs, hierarchy} =
        HierarchyWalker.find_unique_figures(config, root_figures, refs_with_ids)

      layers =
        for layer <- unique_figs do
          case layer do
            {{%Renewex.Storable{
                class_name: class_name,
                fields: %{x: x, y: y, w: w, h: h} = fields
              }, uuid}, z_index} ->
              attrs =
                with %Renewex.Storable{fields: f} <- Map.get(fields, :attributes) do
                  f.attributes |> Enum.into(%{}, fn {key, _type, value} -> {key, value} end)
                else
                  _ -> nil
                end

              style = Config.layer_style_for(config, :box, attrs)

              {shape_name, shape_attributes} =
                Config.convert_shape(config, class_name, fields, attrs)

              %{
                "semantic_tag" => class_name,
                "z_index" => z_index,
                "hidden" => Config.convert_attrs_hidden(config, attrs),
                "id" => uuid,
                "box" => %{
                  "position_x" => x,
                  "position_y" => y,
                  "width" => w,
                  "height" => h,
                  "symbol_shape_attributes" => shape_attributes,
                  "symbol_shape_id" => Map.get(symbol_ids, shape_name)
                },
                "style" => style
              }

            {{%Renewex.Storable{
                class_name: class_name,
                fields: %{text: body, fOriginX: x, fOriginY: y} = fields
              }, uuid}, z_index} ->
              attrs =
                with %Renewex.Storable{fields: f} <- Map.get(fields, :attributes) do
                  f.attributes |> Enum.into(%{}, fn {key, _type, value} -> {key, value} end)
                else
                  _ -> nil
                end

              layer_style = Config.layer_style_for(config, :text, attrs)
              text_style = Config.text_style(config, class_name, fields, attrs)

              %{
                "semantic_tag" => class_name,
                "z_index" => z_index,
                "hidden" => Config.convert_attrs_hidden(config, attrs),
                "id" => uuid,
                "style" => layer_style,
                "text" => %{
                  "position_x" => x,
                  "position_y" => y,
                  "body" => if(is_nil(body), do: "", else: body),
                  "style" => text_style
                }
              }

            {{%Renewex.Storable{
                class_name: class_name,
                fields: %{points: [_, _ | _] = points} = fields
              }, uuid}, z_index} ->
              %{x: start_x, y: start_y} = hd(points) |> Enum.into(%{})
              %{x: end_x, y: end_y} = List.last(points) |> Enum.into(%{})

              attrs =
                with %Renewex.Storable{fields: f} <- Map.get(fields, :attributes) do
                  f.attributes |> Enum.into(%{}, fn {key, _type, value} -> {key, value} end)
                else
                  _ -> nil
                end

              layer_style =
                Config.layer_style_for(config, :edge, attrs)
                |> then(fn
                  nil ->
                    nil

                  %{} = map ->
                    Map.update(map, "background_color", nil, fn _ ->
                      Config.convert_line_decoration_background(
                        config,
                        resolve_ref(refs, Map.get(fields, :start_decoration)),
                        resolve_ref(refs, Map.get(fields, :end_decoration))
                      )
                    end)
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
                  Map.get(
                    symbol_ids,
                    Config.convert_line_decoration(
                      config,
                      resolve_ref(refs, Map.get(fields, :start_decoration))
                    )
                  ),
                "target_tip_symbol_shape_id" =>
                  Map.get(
                    symbol_ids,
                    Config.convert_line_decoration(
                      config,
                      resolve_ref(refs, Map.get(fields, :end_decoration))
                    )
                  )
              }

              %{
                "semantic_tag" => class_name,
                "z_index" => z_index,
                "hidden" => Config.convert_attrs_hidden(config, attrs),
                "id" => uuid,
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

            {{%Renewex.Storable{
                class_name: class_name
              }, uuid}, z_index} ->
              %{
                "semantic_tag" => class_name,
                "z_index" => z_index,
                "id" => uuid
              }
          end
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

  def resolve_ref(refs, {:ref, r}), do: Enum.at(refs, r)
  def resolve_ref(_, nil), do: nil
  def resolve_ref(_, noref), do: noref
end
