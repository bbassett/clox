defmodule CloxTest do
  use ExUnit.Case, async: false
  use ExCheck

  def time do
    bind int(1_000_000_000, 2_000_000_000), fn(ts) ->
      Timex.DateTime.from_seconds(ts)
    end
  end

  def range do
    bind {time, int(0, 1_000_000)}, fn({time, inc}) ->
      {time, Timex.DateTime.shift(time, [seconds: inc])}
    end
  end

  property :keys_for_time do
    for_all t in time do
      {:ok, keys} = Clox.keys_for_time(t)
      _keys = Enum.map(keys, &(elem(Clox.format(&1), 1)))
      # TODO how do we assert this is correct?
      true
    end
  end

  property :smart_range do
    for_all {{b, e}, steps} in {range, int(1, 30)} do
      {:ok, keys} = Clox.smart_range(b, e, steps)
      _keys = Enum.map(keys, &(elem(Clox.format(&1), 1)))
      # TODO how do we assert this is correct?
      true
    end
  end
end
