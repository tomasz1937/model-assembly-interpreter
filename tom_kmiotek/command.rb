# Tomasz Kmiotek
# 3/12/2024
# 677236512 - tkmiot2

# Command Super Class
class Command
  attr_reader :opcode

  def initialize(opcode)
    @opcode = opcode
  end

  def execute
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end
end

# Command to declare a symbolic variable
class DECCommand < Command
  def initialize(ali)
    super('DEC')
    @ali = ali
  end

  def execute(instruction)
    symbol = instruction.split(" ")[1]
    @ali.declare_symbol(symbol)
  end
end

# Command to load a symbol into the accumulator
class LDACommand < Command
  def initialize(ali)
    super('LDA')
    @ali = ali
  end

  def execute(instruction)
    symbol = instruction.split(" ")[1]
    @ali.lda_symbol(symbol)
  end
end

# Command to load an integer value into the accumulator
class LDICommand < Command
  def initialize(ali)
    super('LDI')
    @ali = ali
  end

  def execute(instruction)
    value = instruction.split(" ")[1].to_i
    @ali.load_integer(value)
  end
end

# Command to store content of accumulator into data memory at address of symbol
class STRCommand < Command
  def initialize(ali)
    super('STR')
    @ali = ali
  end

  def execute(instruction)
    symbol = instruction.split(" ")[1]
    @ali.store_accumulator(symbol)
  end
end

# Command to exchange the contents of registers A and B
class XCHCommand < Command
  def initialize(ali)
    super('XCH')
    @ali = ali
  end

  def execute(instruction)
    @ali.exchange_registers
  end
end

# Command to add the contents of registers A and B
class ADDCommand < Command
  def initialize(ali)
    super('ADD')
    @ali = ali
  end

  def execute(instruction)
    @ali.add_registers
  end
end

# Command for subtraction
class SUBCommand < Command
  def initialize(ali)
    super('SUB')
    @ali = ali
  end

  def execute(instruction)
    @ali.sub_registers
  end
end

# Command for jump
class JMPCommand < Command
  def initialize(ali)
    super('JMP')
    @ali = ali
  end

  def execute(instruction)
    address = instruction.split(" ")[1].to_i
    @ali.program_counter = address - 1
  end
end

# Command for jump-if ZB set
class JZSCommand < Command
  def initialize(ali)
    super('JZS')
    @ali = ali
  end

  def execute(instruction)
    address = instruction.split(" ")[1].to_i
    @ali.program_counter = address - 1 if @ali.zero_result_bit == 1
  end
end

# Command for jump-if OF bit set
class JVSCommand < Command
  def initialize(ali)
    super('JVS')
    @ali = ali
  end

  def execute(instruction)
    address = instruction.split(" ")[1].to_i
    @ali.program_counter = address - 1 if @ali.overflow_bit == 1
  end
end

# Command for halt
class HLTCommand < Command
  def initialize(ali)
    super('HLT')
    @ali = ali
  end
  def execute(instruction)
    @ali.halt = true
  end
end

# Assembly Language Interpreter (ALI) class
class ALI
  attr_accessor :memory, :program_counter, :accumulator, :done, :data_register, :overflow_bit, :zero_result_bit, :halt

  MAX_PROGRAM_COUNTER = 127
  PROGRAM_CODE_START_ADDRESS = 0
  PROGRAM_DATA_START_ADDRESS = 128
  MAX_32_BIT_VALUE = 2**31 - 1
  MIN_32_BIT_VALUE = -2**31
  MAX_INSTRUCTIONS = 1000

  # Initialize memory, registers, counter, etc.
  def initialize
    @memory = Array.new(256, 0) # Initialize memory with zeros
    @program_counter = 0
    @accumulator = 0
    @data_register = 0
    @zero_result_bit = 0
    @overflow_bit = 0
    @halt = false
    @symbol_table = {}
    @done = false
    @end_of_program = 0
    @instruction_count = 0
  end

  # Load the program into memory
  def load_program(filename)
    end_of_program_address = 0
    File.foreach(filename).with_index do |line, address|
      load_instruction(line.strip, address)
      end_of_program_address = address
    end
    @end_of_program = end_of_program_address
  end

  # Execute a single line of the program
  def execute_single_line
    return if @halt

    instruction = @memory[@program_counter]

    opcode = instruction.split.first
    command = get_command(opcode)
    command.execute(instruction)

    @program_counter += 1
    @instruction_count += 1
    print_state

    if @instruction_count >= MAX_INSTRUCTIONS
      pause_execution
    end

    if opcode == "HLT" && @program_counter == @end_of_program
      @done = true
    end
  end

  # Execute the whole program
  def execute_all
    stop = false

    until stop
      instruction = @memory[@program_counter]

      opcode = instruction.split.first
      command = get_command(opcode)
      command.execute(instruction)

      @program_counter += 1
      @instruction_count += 1

      if opcode == "HLT"
        stop = true
        @done = true
      end

      if opcode == "HLT" && @program_counter == @end_of_program
        stop = true
        @done = true
      end

      if @instruction_count >= MAX_INSTRUCTIONS
        pause_execution
      end
    end
    print_state
  end

  # Put instruction into memory
  def load_instruction(instruction, address)
    @memory[address] = instruction
  end

  # Declare a new symbol
  def declare_symbol(symbol)
    address = find_available_data_memory_address
    @symbol_table[symbol] = address
  end

  # Load a symbol into the accumulator
  def lda_symbol(symbol)
    address = @symbol_table[symbol]
    if address.nil?
      puts "Symbol #{symbol} not found in the symbol table."
    else
      @accumulator = @memory[address]
    end
  end

  # Load an integer into the accumulator
  def load_integer(value)
    @accumulator = value
  end

  # Exchange the contents of registers A and B
  def exchange_registers
    @accumulator, @data_register = @data_register, @accumulator
  end

  # Add registers together - store in A
  def add_registers
    @accumulator += @data_register
    handle_overflow_and_zero
  end

  # Subtract register B from A
  def sub_registers
    @accumulator -= @data_register
    handle_overflow_and_zero
  end

  # Store accumulator at address of symbol
  def store_accumulator(symbol)
    address = @symbol_table[symbol]
    if address.nil?
      puts "Symbol #{symbol} not found in the symbol table."
    else
      @memory[address] = @accumulator
    end
  end

  # Print all information
  def print_state
    puts "---- Registers ----"
    puts "A/Accum: #{@accumulator}"
    puts "B/Data: #{@data_register}" # Assuming there's a data register instance variable
    puts "PC: #{@program_counter}"
    puts "ZRB: #{@zero_result_bit}" # Assuming there's a zero-result bit instance variable
    puts "OFB: #{@overflow_bit}" # Assuming there's an overflow bit instance variable

    puts "---- Instruction Memory ----"
    (0...PROGRAM_DATA_START_ADDRESS).each do |address| # Loop through instruction memory
      value = @memory[address]
      if value.is_a?(String)
        if address == @program_counter
          puts "=> #{address}: #{value}"
        else
          puts "   #{address}: #{value}"
        end
      end
    end

    puts "---- Data Memory ----"
    occupied_addresses = @symbol_table.values

    (PROGRAM_DATA_START_ADDRESS...256).each do |address| # Loop through data memory
      value = @memory[address]
      if occupied_addresses.include?(address)
        symbol = @symbol_table.key(address)
        puts "%-5d %-7s: %5d" % [address, symbol, value]
      elsif value != 0
        puts "%-5d: %5d" % [address, value]
      end
    end

    empty_start = occupied_addresses.max.to_i + 1
    puts "%-d - %d  :       0" % [empty_start, 255]
    puts ""
  end

  # Get the next available address
  def find_available_data_memory_address
    base_address = PROGRAM_DATA_START_ADDRESS
    address = base_address

    while @symbol_table.value?(address) && address < (base_address + 255)
      address += 1
    end
    address
  end

  private

  # Handle overflow and zero result
  def handle_overflow_and_zero
    # Check for overflow
    if @accumulator > MAX_32_BIT_VALUE || @accumulator < MIN_32_BIT_VALUE
      @overflow_bit = 1  # Set overflow bit
    else
      @overflow_bit = 0  # Clear overflow bit
    end

    # Check for zero-result
    if @accumulator == 0
      @zero_result_bit = 1
    else
      @zero_result_bit = 0
    end
  end

  # Get the command object based on opcode
  def get_command(opcode)
    case opcode
    when "DEC"
      DECCommand.new(self)
    when "LDA"
      LDACommand.new(self)
    when "STR"
      STRCommand.new(self)
    when "LDI"
      LDICommand.new(self)
    when "XCH"
      XCHCommand.new(self)
    when "ADD"
      ADDCommand.new(self)
    when "SUB"
      SUBCommand.new(self)
    when "JMP"
      JMPCommand.new(self)
    when "JZS"
      JZSCommand.new(self)
    when "JVS"
      JVSCommand.new(self)
    when "HLT"
      HLTCommand.new(self)
    else
      raise "Unknown opcode: #{opcode}"
    end
  end

  # Pause execution and prompt the user to continue or halt
  def pause_execution
    puts "Execution paused after #{@instruction_count} instructions."
    print "Continue execution? (y/n): "
    response = gets.chomp.downcase
    case response
    when 'y'
      puts "Resuming execution..."
      @instruction_count = 0
    when 'n'
      puts "Halting program..."
      @done = true
      @halt = true
    else
      puts "Invalid response. Halting program..."
      @done = true
      @halt = true
    end
  end
end
