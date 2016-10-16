defmodule Nerves.Grove.FourDigitDisplay do
  use Bitwise, only_operators: true

  @moduledoc """
  Seeed Studio [Grove 4-digit display](http://wiki.seeedstudio.com/wiki/Grove_-_4-Digit_Display)

  ## Datasheet

  http://www.mouser.com/catalog/specsheets/Seeed_104030003.pdf

  # Example

      alias Nerves.Grove.FourDigitDisplay

      {:ok, pid} = I2C.ADC.start_link(nil, pin)

      FourDigitDisplay.display_number(pid, pin, 1337)
      :timer.sleep(5000)
      FourDigitDisplay.display_segments(pid, pin, 0, 56)
      FourDigitDisplay.display_segments(pid, pin, 1, 121)
      FourDigitDisplay.display_segments(pid, pin, 2, 121)
      FourDigitDisplay.display_segments(pid, pin, 3, 112)

  # Configuration

      config :nerves_grove, ..., fdd_info: {<i2c file name>, <address>}  
  """

  @default_i2c_file             "i2c-1"
  @default_i2c_address             0x04
  @default_pin                        5

  @pin_output_command                 5
  @init_command                      70
  @set_brightness_command            71
  @write_value_command               72
  @write_value_with_zeroes_command   73
  @write_individual_segments_command 75

  @pin_output_mode                    1

  @doc """
  Start a process that controls the four digit display. The second parameter is the pin number.
  """
  def start_link(_type, pin) do
    {file, address} = Application.get_env(:nerves_grove, :fdd_info) || { @default_i2c_file, @default_i2c_address}
    pin = pin || @default_pin
    with {:ok, pid} <- I2c.start_link(file, address),
         :ok <- I2c.write(pid, <<@pin_output_command, pin, @pin_output_mode, 0>>),
         :ok <- I2c.write(pid, <<@init_command, pin, 0, 0>>),
    do: {:ok, pid}
  end

  @doc """
  Display a four-digit number, without leading zeroes.
    * `pid` is the process' pid, as returned by `start_link`
    * `pin` is the pin number
    * `number` is the 16-bits number to display 
  """
  @spec display_number(pid, pos_integer, 0..65535) :: any
  @spec display_number(pid, pos_integer, pos_integer) :: :ok | :error
  def display_number(pid, pin, number) do
    byte1 = number &&& 0xFF
    byte2 = (number >>> 8) &&& 0xFF
    I2c.write(pid, <<@write_value_command, pin, byte1, byte2>>)
  end

  @doc """
  Display a four-digit number, with leading zeroes.
    * `pid` is the process' pid, as returned by `start_link`
    * `pin` is the pin number
    * `number` is the 16-bits number to display 
  """
  @spec display_number_with_zeroes(pid, pos_integer, 0..65535) :: any
  def display_number_with_zeroes(pid, pin, number) do
    byte1 = number &&& 0xFF
    byte2 = (number >>> 8) &&& 0xFF
    I2c.write(pid, <<@write_value_with_zeroes_command, pin, byte1, byte2>>)
  end

#  def segment_mask(segments) where is_tuple(segments) and tuple_size(segments) do
    
#  end

  @doc """
  Manually set which segments on the display are turned on.
    * `pid` is the process' pid, as returned by `start_link`
    * `pin` is the pin number
    * `number` is the "digit" number (0 to 3).
    * `mask` is used to select which segments are turned on. Each bit (from 0 to 7) represents a different segment, clockwise starting from top, with the middle segment being bit #7. Bit #8 is only used when `number==2` and setting it will light up the middle colon.
  """
  @spec display_segments(pid, pos_integer, 0..4, pos_integer) :: :ok | :error
  def display_segments(pid, pin, number, mask) do
    I2c.write(pid, <<@write_individual_segments_command, pin, number, mask>>)
    :timer.sleep(50)
  end

  @doc """
  Set the display's brightness. Parameters are:
    * `pid` is the process' pid, as returned by `start_link`
    * `pin` is the pin number
    * `b` is the brightness, which is a value between 0 (dimmest) to 7 (brightest) 
  """
  @spec set_brightness(pid, pos_integer, 0..7) :: any
  def set_brightness(pid, pin, b) do
    I2c.write(pid, <<@set_brightness_command, pin, b, 0>>)
  end
end
