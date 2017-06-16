defmodule Hrml do
  @default_value "Not Found!"
  @attrs_key :_attrs

  def parse(input) do
    [header | rest] = String.split(input, "\n")
    [source_lines, _] = parse_lines_from_header(header)
    {source, queries} = Enum.split(rest, source_lines)
    context = build_context_from_source(source)

    run_queries(queries, context)
    |> Enum.join("\n")
  end

  defp parse_lines_from_header(header) do
    header
    |> String.split(" ")
    |> Enum.map(fn(v) ->
      {num, ""} = Integer.parse(v)
      num
    end)
  end

  defp build_context_from_source(source, context \\ %{}, path \\ [])
  defp build_context_from_source([], context, _current), do: context
  defp build_context_from_source([line|rest], context, path) do
    {new_context, new_path} =
      {context, path}
      |> update_context_with_opening_tag(line)
      |> update_context_with_closing_tag(line)

    build_context_from_source(rest, new_context, new_path)
  end

  defp update_context_with_opening_tag({context, path}, line) do
    case Regex.run(~r{<(\w+) (.+)>}, line) do
      nil -> {context, path}
      [_, tag_name, attributes] ->
        new_path = path ++ [tag_name]
        attrs_path = new_path ++ [@attrs_key]

        new_context =
          context
          |> put_in(new_path, %{})
          |> put_in(attrs_path, %{})

        case Regex.scan(~r{(\w+) = "([^"]+)"}, attributes) do
          [] -> {new_context, new_path}
          matches ->
            result =
              matches
              |> Enum.reduce(new_context, fn([_, name, value], acc) ->
                put_in(acc, attrs_path ++ [name], value)
              end)

            {result, new_path}
        end
    end
  end

  defp update_context_with_closing_tag({context, path}, line) do
    case Regex.run(~r{</(\w+)>}, line) do
      nil -> {context, path}
      [_, tag] ->
        case List.last(path) do
          ^tag ->
            {previous, _last} = Enum.split(path, -1)
            {context, previous}
          _other ->
            IO.puts "Unrecognized closing tag: #{inspect tag}"
            {context, path}
        end
    end
  end

  defp run_queries(queries, context) do
    queries
    |> Enum.map(fn query ->
      case String.split(query, "~") do
        [path, attr] ->
          path = String.split(path, ".")
          get_in(context, path ++ [@attrs_key, attr]) || @default_value
        _other -> nil
      end
    end)
  end
end
