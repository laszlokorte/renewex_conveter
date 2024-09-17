defmodule RenewexConverter.HierarchyWalker do
  alias RenewexConverter.Config

  def find_unique_figures(config, root_figures, refs_with_ids) do
    unique_figures =
      root_figures
      |> Enum.with_index()
      |> Enum.flat_map(fn {fig, i} ->
        collect_nested_figures(config, fig, i, refs_with_ids)
      end)
      |> Enum.group_by(fn {{_, uid}, _} -> uid end)
      |> Enum.map(fn {_uid, dupls} -> List.last(dupls) end)

    hierarchy =
      Enum.flat_map(root_figures, fn fig ->
        collect_hierarchy(config, fig, refs_with_ids)
      end)

    {unique_figures, hierarchy}
  end

  defp collect_nested_figures(%Config{} = conf, {:ref, r}, index, refs_with_ids) do
    case Enum.at(refs_with_ids, r) do
      {%Renewex.Storable{class_name: class_name, fields: %{figures: figures}}, _} = el ->
        Config.fix_hierarchy_order(conf, figures, class_name)
        |> Enum.with_index()
        |> Enum.flat_map(fn {fig, i} ->
          collect_nested_figures(conf, fig, i, refs_with_ids)
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

  defp collect_hierarchy(%Config{} = conf, {:ref, r}, refs_with_ids, ancestors \\ []) do
    case Enum.at(refs_with_ids, r) do
      {%Renewex.Storable{class_name: class_name, fields: %{figures: figures}}, own_id} ->
        Config.fix_hierarchy_order(conf, figures, class_name)
        |> Enum.flat_map(fn fig ->
          collect_hierarchy(
            conf,
            fig,
            refs_with_ids,
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
            {parent_id, distance} -> {parent_id, own_id, distance + 1}
          end)
        )
        |> Enum.to_list()

      {%Renewex.Storable{}, child_id} ->
        Enum.map(ancestors, fn
          {parent_id, distance} -> {parent_id, child_id, distance + 1}
        end)
        |> Enum.concat([{child_id, child_id, 0}])

      _ ->
        []
    end
  end
end
