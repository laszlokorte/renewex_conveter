defmodule RenewexConverter.HierarchyWalker do
  alias RenewexConverter.DocumentReader
  alias RenewexConverter.Conversion

  def find_unique_figures(
        %RenewexConverter.DocumentReader{
          document: %Renewex.Document{
            root: %Renewex.Storable{fields: %{figures: root_figures}}
          }
        } = reader
      ) do
    unique_figures =
      root_figures
      |> Enum.with_index()
      |> Enum.flat_map(fn {fig, i} ->
        collect_nested_figures(reader, fig, i)
      end)
      |> Enum.group_by(fn {{_, uid}, _} -> uid end)
      |> Enum.map(fn {_uid, dupls} -> List.last(dupls) end)
      |> Enum.map(fn {{storable, uid}, zindex} ->
        %{
          storable: storable,
          id: uid,
          zindex: zindex
        }
      end)

    hierarchy =
      Enum.flat_map(root_figures, fn fig ->
        collect_hierarchy(reader, fig)
      end)

    {unique_figures, hierarchy}
  end

  defp collect_nested_figures(%DocumentReader{id_map: id_map} = reader, {:ref, r}, index) do
    case Enum.at(id_map, r) do
      {%Renewex.Storable{class_name: class_name, fields: %{figures: figures}}, _} = el ->
        Conversion.fix_hierarchy_order(reader, figures, class_name)
        |> Enum.with_index()
        |> Enum.flat_map(fn {fig, i} ->
          collect_nested_figures(reader, fig, i)
        end)
        |> then(
          &Enum.concat(
            [{el, index}],
            &1
          )
        )
        |> Enum.to_list()

      {%Renewex.Storable{}, _} = el ->
        [{el, index}]

      _ ->
        []
    end
  end

  defp collect_hierarchy(
         %RenewexConverter.DocumentReader{
           document: %Renewex.Document{},
           id_map: id_map
         } = reader,
         {:ref, r},
         ancestors \\ []
       ) do
    case Enum.at(id_map, r) do
      {%Renewex.Storable{class_name: class_name, fields: %{figures: figures}}, own_id} ->
        Conversion.fix_hierarchy_order(reader, figures, class_name)
        |> Enum.flat_map(fn fig ->
          collect_hierarchy(
            reader,
            fig,
            [
              {own_id, 0}
              | Enum.map(ancestors, fn
                  {parent_id, distance} -> {parent_id, distance + 1}
                end)
            ]
          )
        end)
        |> Enum.concat([{own_id, own_id, 0}])
        |> Enum.concat(
          Enum.map(ancestors, fn
            {parent_id, distance} ->
              %LayeredDocument.Nesting{
                ancestor_id: parent_id,
                descendant_id: own_id,
                depth: distance + 1
              }
          end)
        )
        |> Enum.to_list()

      {%Renewex.Storable{}, child_id} ->
        Enum.map(ancestors, fn
          {parent_id, distance} ->
            %LayeredDocument.Nesting{
              ancestor_id: parent_id,
              descendant_id: child_id,
              depth: distance + 1
            }
        end)
        |> Enum.concat([
          %LayeredDocument.Nesting{
            ancestor_id: child_id,
            descendant_id: child_id,
            depth: 0
          }
        ])

      _ ->
        []
    end
  end
end
