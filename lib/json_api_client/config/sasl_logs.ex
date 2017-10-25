defmodule JsonApiClient.Config.SASLLogs do
  @moduledoc """
  Logs Translator to skip SASL supervisor, crash and progress reports.
  """

  def suppress(_min_level, :info, :report, {:progress, _data}), do: :skip

  def suppress(_min_level, _level, _kind, _data), do: :none
end
