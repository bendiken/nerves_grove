# This is free and unencumbered software released into the public domain.

defmodule Nerves.Grove.LED do
  @moduledoc """
  Seeed Studio [Grove LED](http://wiki.seeedstudio.com/wiki/Grove_-_LED)

  # Example

      alias Nerves.Grove.LED

      {:ok, desc} = LED.start_link(pin)

      LED.blink(desc)

  # Configuration

  Leds can be driven either directly by GPIOs or through and i2c bus.
  Their configuration is specified as follows:

      config :nerves_grove, ..., pins: [
                                        {2, :gpio, {}},
                                        {4, :i2c, {"i2c-1", 0x04}} ]

  In the case of GPIOs, only the pin number along with the atom `:gpio` and
  an empty tuple is necessary. In the case of i2c, the pin number, `:i2c`, and
  a tuple containing the file name and i2c address of the controller chip are
  necessary.
  """

  @i2c_digital_read_command  1
  @i2c_digital_write_command 2
  @i2c_mode_command  5

  @spec start_link(pos_integer) :: {:ok, pid} | {:error, any}
  def start_link(pin) when is_integer(pin) do
    # Look for the pin descriptor in the documentation. Assume GPIO otherwise.
    pins = Application.get_env(:nerves_grove, :pins, [])
    { _, type, extra } = Enum.find(pins, fn {pn,_,_} -> pn == pin end) || {pin, :gpio, nil}

    # Depending on the "line" type, proceed to set the pin as an output GPIO.
    case type do
      :gpio ->
        {success, pid} = Gpio.start_link(pin, :output)
        {success, {pid, :gpio, pin}}
      :i2c ->
        { fname, address } = extra
        with {:ok, pid} <- I2c.start_link(fname, address),
             :ok <- I2c.write(pid, <<@i2c_mode_command, pin, 1, 0>>),
           do: {:ok, {pid, :i2c, pin}}
      _ -> {:error, "Invalid type #{type}"}
    end    
  end

  @doc "Blinks the LED for a specified duration."
  @spec blink({pid, Keyword.T, pos_integer}, number) :: any
  def blink(data, duration \\ 0.2) when is_tuple(data) and is_number(duration) do
    duration_in_ms = duration * 1000 |> round
    on(data)
    :timer.sleep(duration_in_ms)
    off(data)
  end

  @doc "Switches on the LED."
  @spec on({pid,Keyword.T,pos_integer}) :: any
  def on(data) when is_tuple(data) do
    {pid, type, pin} = data
    case type do
      :gpio -> Gpio.write(pid, 1)
      :i2c  -> I2c.write(pid, <<@i2c_digital_write_command, pin, 1, 0>>)
      _     -> {:error, "Invalid line type"}
    end
  end

  @doc "Switches off the LED."
  @spec off({pid, Keyword.T, pos_integer}) :: any
  def off(data) when is_tuple(data) do
    {pid, type, pin} = data
    case type do
      :gpio -> Gpio.write(pin, 1)
      :i2c  -> I2c.write(pid, <<@i2c_digital_write_command, pin, 0, 0>>)
      _     -> {:error, "Invalid line type"}
    end
  end
end
