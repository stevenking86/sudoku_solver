class HomeController < ApplicationController

  def index

  end

  def results
    sudoku_string = Solver.make_string(params)
    # if sudoku cannot complete, sudoku solver will timeout after 1 second
    begin
    	@result = Timeout::timeout(1) do
		    @answer = Solver.solve(sudoku_string)
	        if request.xhr?
		    	render :json => @answer
		    end
    	end
    rescue Timeout::Error
    	render js: "alert('The Sudoku Board is invalid. Please reset and try again.');"
    end
  end

end
