# The book numbers 起势 and 收势 from （一） again, apart from the main sequence, so a movement's
# position in the routine (number) and the numeral printed in the book can differ.
class AddBookNumberToMovements < ActiveRecord::Migration[8.1]
  def change
    add_column :movements, :book_number, :integer
  end
end
