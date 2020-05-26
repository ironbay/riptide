# Queries

Riptide Queries are used to fetch data from the tree. They can return a section of the tree, optionally limiting the range and number of results (useful for paging).

```elixir
iex(1)> Riptide.query_path!(["todo:info"])
%{
    "todo:info" => %{
        "todo1" => %{
            "key" => "todo1"
        },
        "todo2" => %{
            "key" => "todo2"
        },
    },
}

```

For full documentation checkout the [hexdocs page](https://hexdocs.pm/riptide/Riptide)

---

## Structure

Queries are expressed as a nested map specifying the paths that should be returned. You can think of them as an outline of the data that they're requesting. Queries can request multiple paths and specify limitations per path. These are the standard options that can be used to limit the results under a specific path

- `:min` - Starting range of query, optional
- `:max` - Ending range of query, optional
- `:limit` - Max number of results, optional

&nbsp;

## Examples

Fetch everything under `todo:info`

```json
{
  "todo:info": {}
}
```

Fetch everything under `todo:info` as well as `user:info.ahab`

```json
{
  "todo:info": {},
  "user:info": {
    "ahab": {}
  }
}
```

Fetch the first 10 things under `todo:info`

```json
{
  "todo:info": { "limit": 10 }
}
```

Fetch the first 10 things under `todo:info` starting from `todo:info.todo5`

```json
{
  "todo:info": { "min": "todo5", "limit": 10 }
}
```
