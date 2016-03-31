class Solver < ActiveRecord::Base

  def self.make_string(params)
    params.delete("utf8")
    params.delete("authenticity_token")
    params.delete("commit")
    params.delete("controller")
    params.delete("action")
    sodoku_string = ""
    params.values.each do |val|
      if val == ""
        sodoku_string << '-'
      else
        sodoku_string << val
      end
    end
    return sodoku_string
  end


  def self.checker(num, line)
    !line.include? num
  end

  def self.build_possibility_hash(puzzle, single_switch=true)

    transposed_puzzle = transpose_puzzle(puzzle)
    boxed_puzzle = box_puzzle(puzzle)

    possibility_hash = {}


    puzzle.each_with_index do |row, row_index|
      row.each_with_index do |square, col_index|

        if square == "-"
          possibilities = []

          (1..9).each do |num|

            can_put_in_row = checker(num, row)
            can_put_in_col = checker(num, transposed_puzzle[col_index])

            # determine box index to plug in to checker to check box
            box_index = get_box_index(row_index, col_index)

            can_put_in_box = checker(num, boxed_puzzle[box_index])

            if can_put_in_box && can_put_in_col && can_put_in_row
              possibilities << num
            end #if
          end #do
          if single_switch == true
            if possibilities.length == 1
              possibility_hash[[row_index, col_index]] = possibilities[0]
            end
          else
            possibility_hash[[row_index, col_index]] = possibilities
          end

        end #if square = "-"
      end
    end
    if single_switch == true
      return possibility_hash
    else
      unique_array = hash_rows(possibility_hash)
      unique_array += hash_cols(possibility_hash)
      unique_array += hash_boxes(possibility_hash)
      return unique(unique_array)
    end
  end




  def self.answer_pusher(puzzle, single_possibility_hash)

    single_possibility_hash.each do |key, value|
      y = key[0]
      x = key[1]
      puzzle[y][x] = value
    end

    puzzle
  end






  def self.build_puzzle(string)
    array = string.split('')
    array.map! do |x|
      if x != '-'
        x.to_i
      else
        x = x
      end
    end
    array = array.each_slice(9).to_a
    array
  end


  def self.transpose_puzzle(array)
    array.transpose
  end


  def self.solved?(board_1)
    board_2 = transpose_puzzle(board_1)
    board_3 = box_puzzle(board_1)
    counter = 1
    while counter < 10
      board_1.each do |line|
        if line.include?(counter) == false
          return false
        end
      end
      counter +=1
    end
    counter = 1
    while counter < 10
      board_2.each do |line|
        if line.include?(counter) == false
          return false
        end
      end
      counter += 1
    end
    counter = 1
    while counter < 10
      board_3.each do |line|
        if line.include?(counter) == false
          return false
        end
      end
      counter +=1
    end
    true
  end


  def self.pretty_board(board)
    prettiness = board.map do |line|
      line.join(' ') << "\n"
    end
    prettiness.join('').to_s
  end

  def self.box_puzzle(array)
    boxy = array.map{|line| line.each_slice(3).to_a}
    final_box = boxy[0].zip(boxy[1],boxy[2])
    final_box += boxy[3].zip(boxy[4],boxy[5])
    final_box += boxy[6].zip(boxy[7],boxy[8])
    final_box.map! do |line|
      line.flatten
    end
  end

  def self.hash_rows(hash)
    (0..8).each_with_object([]) {|num, array| array[num] = hash.select{|k,v| k[0] == num}}
  end

  def self.hash_cols(hash)
    (0..8).each_with_object([]) {|num, array| array[num] = hash.select{|k,v| k[1] == num}}
  end

  def self.hash_boxes(hash)
    boxes = []
    # box 0 = subhash of all elements where 0 < row < 2 and 0 < col < 2
    # box 1 = subhash of all elements where 0 < row < 2 and 3 < col < 5
    # etc
    (0..8).each do |box_num|
      boxes[box_num] = hash.select do |k,v|
        box_num == get_box_index(k[0],k[1])
      end
    end

    boxes
  end


  def self.unique(array)
    unique_possibility_hash = {}
    array.each do |hash|
      1.upto(9) do |num|
       thing = hash.select {|k,v| v.include?(num)}
       if thing.length == 1
         unique_possibility_hash[(thing.keys[0])] = num
       end
     end
    end
    unique_possibility_hash
  end


  def self.array_of_blanks(puzzle)
    blanks = []
    puzzle.each_with_index do |row, row_index|
      row.each_with_index do |cell, col_index|
        if cell == "-"
          blanks << [row_index, col_index]
        end
      end
    end
    blanks
  end

  def self.recursive_solve(puzzle, blanks)
    # base case
    if solved?(puzzle)
      return puzzle
    end

    if blanks.empty?
      return puzzle
    end

    row = blanks[0][0]
    col = blanks[0][1]


    temp_blanks = blanks.slice(1..-1)

    1.upto(9) do |num|
      if all_checks_ok(puzzle, num, row, col)
        temp_puzzle = puzzle.dup
        temp_puzzle[row][col] = num
        next_recursion = recursive_solve(temp_puzzle, temp_blanks)
        if solved?(next_recursion)
          return next_recursion
        end
      end
    end


    puzzle[row][col] = "-"
    return puzzle

  end

  def self.get_box_index(row, col)
    [
      [0, 0, 0, 1, 1, 1, 2, 2, 2],
      [0, 0, 0, 1, 1, 1, 2, 2, 2],
      [0, 0, 0, 1, 1, 1, 2, 2, 2],
      [3, 3, 3, 4, 4, 4, 5, 5, 5],
      [3, 3, 3, 4, 4, 4, 5, 5, 5],
      [3, 3, 3, 4, 4, 4, 5, 5, 5],
      [6, 6, 6, 7, 7, 7, 8, 8, 8],
      [6, 6, 6, 7, 7, 7, 8, 8, 8],
      [6, 6, 6, 7, 7, 7, 8, 8, 8]
    ][row][col]
  end


  def self.all_checks_ok(puzzle, num, row, col)

    if checker(num, puzzle[row]) == false
      return false
    end
    if checker(num, transpose_puzzle(puzzle)[col]) == false
      return false
    end
    box_index = get_box_index(row, col)

    if  checker(num, box_puzzle(puzzle)[box_index]) == false
      return false
    end

    true

  end


  def self.solve(puzzle_string)
    puzzle = build_puzzle(puzzle_string)
    begin
      possibilities = build_possibility_hash(puzzle)
      # if there's anything in the possibilities hash
      if !possibilities.empty?
        answer_pusher(puzzle, possibilities)
      else
        if solved?(puzzle)
          puts pretty_board(puzzle)
          return puzzle
        else
          next_attempt = build_possibility_hash(puzzle, false)
          if !next_attempt.empty?
            answer_pusher(puzzle, next_attempt)
          end
        end
      end
    end while !possibilities.empty? || !next_attempt.empty?
    blanks = array_of_blanks(puzzle)
    puzzle = recursive_solve(puzzle, blanks)
    puts pretty_board(puzzle)
    puzzle
  end

end


#Call solve on the string and the result will be outputed to a pretty_board