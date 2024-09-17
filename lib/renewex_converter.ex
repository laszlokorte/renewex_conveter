defmodule RenewexConverter do
  def consume_document(%Renewex.Document{} = doc) do
    RenewexConverter.DocumentReader.read(
      RenewexConverter.Config.new(Renewex.Grammar.new(doc.version)),
      doc
    )
  end

  def produce_document(%RenewexConverter.LayeredDocument{} = _document) do
  end
end
