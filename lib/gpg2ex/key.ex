defmodule Gpg2ex.Key do
  @moduledoc """
  Defines the `Key` struct.
  """

  @doc """
  The `key` struct contains information extracted after running `gpg2` commands.
  """
  defstruct [
    :key_id,
    :realname,
    :email,
    :trust_level,
  ]
end
