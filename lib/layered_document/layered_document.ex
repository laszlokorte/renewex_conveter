defmodule RenewexConverter.LayeredDocument do
  defstruct [
    :version,
    :kind,
    :layers,
    :hierarchy,
    :hyperlinks
  ]

  def new(
        version,
        kind,
        layers,
        hierarchy,
        hyperlinks
      ),
      do: %RenewexConverter.LayeredDocument{
        version: version,
        kind: kind,
        layers: layers,
        hierarchy: hierarchy,
        hyperlinks: hyperlinks
      }
end
