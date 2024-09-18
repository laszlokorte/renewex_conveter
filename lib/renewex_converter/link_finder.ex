defmodule RenewexConverter.LinkFinder do
  alias Renewex.Hierarchy

  def find_links(%RenewexConverter.DocumentReader{grammar: grammar, id_map: id_map}, unique_figs) do
    for %{
          storable: %Renewex.Storable{
            class_name: class_name,
            fields: %{fParent: {:ref, text_parent_ref}}
          },
          id: source_id
        } <- unique_figs,
        Hierarchy.is_subtype_of(grammar, class_name, "CH.ifa.draw.figures.TextFigure"),
        {_, target_id} = Enum.at(id_map, text_parent_ref),
        not is_nil(target_id) do
      %RenewexConverter.Hyperlink{
        source_id: source_id,
        target_id: target_id
      }
    end
  end
end
