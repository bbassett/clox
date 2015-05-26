defmodule Clox do
  
  alias Timex.Date
  alias Timex.DateFormat

  @minute_prefix "m"
  @ten_minute_prefix "T"
  @hour_prefix "H"
  @day_prefix "D"
  @week_prefix "W"
  @month_prefix "M"

  @minute_conversion 60

  @minute_res 1
  @ten_minute_res 10
  @hour_res 60
  @day_res @hour_res * 24
  @week_res @day_res * 7
  @month_res @week_res * 4

  @granularities [
    @minute_prefix,
    @ten_minute_prefix,
    @hour_prefix,
    @day_prefix,
    @week_prefix,
    @month_prefix
  ]

  @resolutions [
    {@minute_prefix, @minute_res},
    {@ten_minute_prefix, @ten_minute_res},
    {@hour_prefix, @hour_res},
    {@day_prefix, @day_res},
    {@week_prefix, @week_res},
    {@month_prefix, @month_res}
  ]

  @epoch {1970,1,1} |> Date.from |> Date.to_secs

  @date_format "{ISOz}"

  @doc """
  Get a list of keys for a time. The returned keys are split into buckets
  based on the granularities (minute, ten minute, hour, day, week, month).

  These keys may be used to save a counter for a metric
  """
  def keys_for_time(time \\ Date.now) do
    time = time
    |> parse
    |> Date.set([second: 0, ms: 0])

    keys = unquote(for granularity <- @granularities do
      quote do
        unquote(granularity) <> pack(truncate(unquote(Macro.var(:time, nil)), unquote(granularity)))
      end
    end)

    {:ok, keys}
  end

  @doc """
  Format a key into a format, defaulting to ISOz
  """
  def format(time, format \\ @date_format) do
    {:ok, time
    |> parse
    |> DateFormat.format!(format)}
  end

  @doc """
  Get a list of granularities supported.
  """
  def granularities do
    {:ok, @granularities}
  end

  @doc """
  Get a range of keys between two dates. The granularity will be derived based on steps.
  """
  def smart_range(begining, ending, steps \\ 20)
  def smart_range(begining, ending, steps) when is_binary(begining) do
    smart_range(DateFormat.parse!(begining, @date_format), ending, steps)
  end
  def smart_range(begining, ending, steps) when is_binary(ending) do
    smart_range(begining, DateFormat.parse!(ending, @date_format), steps)
  end
  def smart_range(begining, ending, steps) do
    diff = Date.diff(begining, ending, :mins)
    granularity = diff_to_granularity(diff, steps)
    range(begining, ending, granularity)
  end

  for {granularity, resolution} <- @resolutions do
    defp diff_to_granularity(diff, steps) when div(diff, unquote(resolution)) < steps do
      unquote(granularity)
    end
  end
  defp diff_to_granularity(_, _) do
    unquote(List.last(@granularities))
  end

  @doc """
  Get a range of keys given a granularity.
  """
  def range(begining, ending, granularity)
  def range(begining, ending, granularity) when is_binary(begining) do
    range(DateFormat.parse!(begining, @date_format), ending, granularity)
  end
  def range(begining, ending, granularity) when is_binary(ending) do
    range(begining, DateFormat.parse!(ending, @date_format), granularity)
  end
  for {granularity, resolution} <- @resolutions do
    def range(begining, ending, unquote(granularity)) do
      ending = ending
      |> truncate(unquote(granularity))
      |> + unquote(resolution)

      out = begining
      |> truncate(unquote(granularity))
      |> iter(ending, unquote(granularity), unquote(resolution), [])
      {:ok, out}
    end
  end

  defp iter(begining, ending, granularity, resolution, acc) when begining <= ending do
    key = granularity <> pack(begining)
    iter(begining + resolution, ending, granularity, resolution, [key | acc])
  end
  defp iter(_, _, _, _, acc) do
    :lists.reverse(acc)
  end

  @doc """
  Determine if the key is frozen.
  """
  def is_frozen?(time, now \\ Date.now)
  for prefix <- @granularities do
    def is_frozen?(<<unquote(prefix), time :: binary>>, now) do
      {:ok, truncate(now, unquote(prefix)) > unpack(time)}
    end
  end

  defp parse(nil), do: Date.now
  defp parse(""), do: Date.now
  defp parse(time) when is_integer(time), do: Date.from(time, :secs)
  defp parse(time = %Timex.DateTime{}), do: time
  for prefix <- @granularities do
    defp parse(<<unquote(prefix), time :: binary>>) do
      time
      |> unpack
      |> from_minutes
      |> Date.from(:secs)
    end
  end
  defp parse(time) when is_binary(time) do
    DateFormat.parse!(time, @date_format)
  end

  defp truncate(time, @minute_prefix) do
    time
    |> to_minutes
  end
  defp truncate(time, @ten_minute_prefix) do
    time
    |> to_minutes
    |> div(@ten_minute_res)
    |> Kernel.*(@ten_minute_res)
  end
  defp truncate(time, @hour_prefix) do
    time
    |> Date.set(minute: 0)
    |> to_minutes
  end
  defp truncate(time, @day_prefix) do
    time
    |> Date.set(minute: 0, hour: 0)
    |> to_minutes
  end
  defp truncate(time, @week_prefix) do
    time
    |> Date.set(minute: 0, hour: 0)
    |> to_minutes
    |> div(@week_res)
    |> Kernel.*(@week_res)
  end
  defp truncate(time, @month_prefix) do
    time
    |> Date.set(minute: 0, hour: 0, day: 1)
    |> to_minutes
  end

  defp to_minutes(date) do
    date
    |> Date.to_secs
    |> - @epoch
    |> div(@minute_conversion)
  end

  defp from_minutes(minutes) do
    minutes
    |> Kernel.*(@minute_conversion)
    |> + @epoch
  end

  defp pack(minutes) do
    minutes
    |> :binary.encode_unsigned
    |> Base.url_encode64
    |> String.replace("=", "")
  end

  defp unpack(time) do
    time
    |> pad
    |> Base.url_decode64!
    |> :binary.decode_unsigned
  end

  for size <- [0,1,2,3] do
    padding = if size != 0 do
      Stream.cycle(["="]) |> Enum.take(4 - size) |> to_string
    else
      ""
    end
    defp pad(buf) when rem(byte_size(buf), 4) == unquote(size) do
      buf <> unquote(padding)
    end
  end
end