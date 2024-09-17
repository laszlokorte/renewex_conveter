defmodule RenewexConverter do
  def consume_document(%Renewex.Document{} = doc) do
    RenewexConverter.DocumentReader.read(RenewexConverter.Config.new(), doc)
  end

  def produce_document(%RenewexConverter.NormalizedDocument{} = _document) do
  end
end
