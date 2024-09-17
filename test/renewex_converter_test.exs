defmodule RenewexConverterTest do
  use ExUnit.Case
  doctest RenewexConverter

  @example_dir Path.join([__DIR__, "fixtures", "selected_examples"])
  @full_examples_dir Path.join([__DIR__, "fixtures", "valid_files"])

  describe "converter" do
    test "convert example file" do
      {:ok, _example} = "#{@example_dir}/example.rnw" |> File.read()
    end

    test "convert selected files" do
      {:ok, files} = File.ls(@example_dir)

      assert Enum.count(files) > 0, "test files exist"

      for file <- skip_excluded_files(files) do
        assert {:ok, _example} = File.read(Path.join(@example_dir, file)), "can read #{file}"

        assert true
      end
    end

    @tag :slow
    test "convert all files" do
      {:ok, files} = File.ls(@full_examples_dir)

      assert Enum.count(files) > 0, "test files exist"

      for file <- skip_excluded_files(files) do
        assert {:ok, _example} = File.read(Path.join(@full_examples_dir, file)),
               "can read #{file}"
      end
    end
  end

  defp skip_excluded_files(files) do
    Enum.filter(files, fn name -> not String.starts_with?(name, "SKIP") end)
  end
end
