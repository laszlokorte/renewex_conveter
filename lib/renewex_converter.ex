defmodule RenewexConverter do
  alias RenewexConverter.Stylesheet
  alias RenewexConverter.Conversion
  alias RenewexConverter.DocumentReader

  def consume_document(%Renewex.Document{} = doc) do
    reader = DocumentReader.new(%Conversion{}, %Stylesheet{}, doc)

    RenewexConverter.DocumentReader.read(reader)
  end

  def produce_document(%RenewexConverter.LayeredDocument{} = _document) do
  end
end
