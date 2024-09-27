defmodule RenewexConverterTest do
  alias Renewex.Hierarchy
  alias Renewex.Storable
  alias RenewexConverter.LayeredDocument
  use ExUnit.Case
  doctest RenewexConverter

  @example_dir Path.join([__DIR__, "fixtures", "selected_examples"])
  @full_examples_dir Path.join([__DIR__, "fixtures", "valid_files"])

  describe "converter" do
    test "convert example file" do
      assert {:ok, content} = "#{@example_dir}/example.rnw" |> File.read()
      assert {:ok, %Renewex.Document{} = doc} = Renewex.parse_document(content)

      assert {:ok, %LayeredDocument{hyperlinks: hyperlinks, layers: layers}} =
               RenewexConverter.consume_document(doc)

      assert Enum.count(hyperlinks) == 23
      assert Enum.count(layers) == 69
    end

    test "convert selected files" do
      {:ok, files} = File.ls(@example_dir)

      assert Enum.count(files) > 0, "test files exist"

      for file <- skip_excluded_files(files) do
        assert {:ok, content} = File.read(Path.join(@example_dir, file)), "can read #{file}"

        assert {:ok,
                %Renewex.Document{root: %Renewex.Storable{fields: %{figures: root_figures}}} = doc} =
                 Renewex.parse_document(content)

        assert {:ok, %LayeredDocument{hyperlinks: hyperlinks, layers: layers}} =
                 RenewexConverter.consume_document(doc)

        assert Enum.count(layers) >= Enum.count(root_figures)
        assert Enum.count(layers) >= Enum.count(hyperlinks)
      end
    end

    @tag :slow
    test "convert all files" do
      {:ok, files} = File.ls(@full_examples_dir)

      assert Enum.count(files) > 0, "test files exist"

      for file <- skip_excluded_files(files) do
        assert {:ok, content} = File.read(Path.join(@full_examples_dir, file)),
               "can read #{file}"

        assert {:ok,
                %Renewex.Document{root: %Renewex.Storable{fields: %{figures: root_figures}}} = doc} =
                 Renewex.parse_document(content)

        assert {:ok, %LayeredDocument{hyperlinks: hyperlinks, layers: layers}} =
                 RenewexConverter.consume_document(doc)

        assert Enum.count(layers) >= Enum.count(root_figures)
        assert Enum.count(layers) >= Enum.count(hyperlinks)
      end
    end
  end

  defp skip_excluded_files(files) do
    Enum.filter(files, fn name -> not String.starts_with?(name, "SKIP") end)
  end
end
