# Tomasz Kmiotek
# 3/12/2024
# 677236512 - tkmiot2

require_relative 'command'

# Instance of the ALI
ali = ALI.new

puts "Enter the file name:"

filename = gets.chomp

# Load the program from the file
ali.load_program(filename)

# Loop for user input
loop do
  puts "Enter command (s for single line, a for all instructions, q to quit):"
  command = gets.chomp.downcase

  case command
  when 's'
    ali.execute_single_line # single line of code
    if ali.done
      puts "Program Complete... Exiting"
      break
    end
  when 'a'
    ali.execute_all # all code
    if ali.done
     puts "Program Complete... Exiting"
     break
    end
  when 'q'
    puts "Exiting"
    break
  else
    puts "Invalid command"
  end
end

