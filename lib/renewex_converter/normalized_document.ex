defmodule RenewexConverter.NormalizedDocument do
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
      do: %RenewexConverter.NormalizedDocument{
        version: version,
        kind: kind,
        layers: layers,
        hierarchy: hierarchy,
        hyperlinks: hyperlinks
      }
end
