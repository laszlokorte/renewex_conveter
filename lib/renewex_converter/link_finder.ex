defmodule RenewexConverter.LinkFinder do
  alias Renewex.Hierarchy

  def find_links(%RenewexConverter.Config{grammar: grammar}, unique_figs, refs_with_ids) do
    for {{%Renewex.Storable{
            class_name: class_name,
            fields: %{fParent: {:ref, text_parent_ref}}
          }, source_id}, _} <- unique_figs,
        target_id =
          Enum.at(refs_with_ids, text_parent_ref)
          |> elem(1),
        not is_nil(target_id),
        Hierarchy.is_subtype_of(grammar, class_name, "CH.ifa.draw.figures.TextFigure") do
      %RenewexConverter.Hyperlink{
        source_id: source_id,
        target_id: target_id
      }
    end
  end
end
