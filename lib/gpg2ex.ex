defmodule Gpg2ex do
  @moduledoc """
  A naïve wrapper around the GnuPG command line utils.
  """

  alias Gpg2ex.Key

  @doc """
  Invokes shell command using Porcelain, then parse the output into a `Key` struct.

  Assuming the output contains GOODSIG line and TRUST_* line:
  ```
  ...
  [GNUPG:] GOODSIG key_id realname (comment) <email>
  ...
  [GNUPG:] TRUST_FULLY 0 pgp
  ```
  """
  def verify(signed_msg) do
    command = Application.get_env(:gpg2ex, :command)
    result =
      Porcelain.shell("#{command} --verify --status-fd 1",
        in: signed_msg,
        err: nil)

    if result.status == 0 do
      lines = cleanup_output(result.out)
      user_str = filter_user_string(lines)

      key = %Key{
        key_id: extract_key_id(lines),
        realname: extract_realname(user_str),
        email: extract_email(user_str),
        trust_level: extract_trust_level(lines),
      }

      {:ok, key}
    else
      {:error, "`#{command} --verify` failed"}
    end
  end

  defp cleanup_output(command_output) do
    command_output
    |> String.split("\n")
    |> Enum.filter(&(String.contains?(&1, "[GNUPG:]")))
  end

  defp extract_key_id(lines) do
    lines
    |> Enum.find(&(String.contains?(&1, "GOODSIG")))
    |> String.split()
    |> Enum.at(2)
  end

  defp filter_user_string(lines) do
    lines
    |> Enum.find(&(String.contains?(&1, "GOODSIG")))
    |> String.split
    |> Enum.slice(3..-1)
    |> Enum.join(" ")
  end

  defp extract_realname(user_string) do
    user_string
    |> String.split(~r{[\(<]})
    |> Enum.at(0)
    |> String.trim()
  end

  defp extract_email(user_string) do
    user_string
    |> String.split
    |> Enum.at(-1)
    |> String.slice(1..-2)
  end

  defp extract_trust_level(lines) do
    lines
    |> Enum.at(-1)
    |> String.split
    |> Enum.at(1)
  end

end
