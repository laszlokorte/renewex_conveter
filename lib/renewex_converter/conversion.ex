defmodule RenewexConverter.Conversion do
  alias RenewexConverter.Conversion

  defstruct []

  def generate_layer_id(%Conversion{}) do
    UUID.uuid4()
  end
end
