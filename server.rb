require "sinatra"
require "pry"
require "pg"

def db_connection
  begin
    connection = PG.connect(dbname: "groceries")
    yield(connection)
  ensure
    connection.close
  end
end

def sql(statement, exec_type, array_items)
  all = db_connection do |conn|
    if exec_type == "exec"
      conn.exec(statement)
    else
      conn.exec_params(statement, array_items)
    end
  end
  all = all.to_a
end

def groceries
  sql("
    SELECT groceries.id, groceries.name
    FROM groceries
    ORDER BY groceries.name
    ", "exec", nil
  )
end

def grocery_first_letters
  letters = []
  groceries.each do |food|
    first_letter = food["name"][0]
    letters << first_letter unless letters.include?(first_letter)
  end
  letters.sort!
end

def filtered_foods(letter)
  sql("
    SELECT groceries.name
    FROM groceries
    WHERE groceries.name LIKE '#{letter}%'
    ", "exec", nil
  )
end

def add_food(name)
  sql("
    INSERT INTO groceries (name)
    VALUES ($1)",
    "exec_params", [name]
  )
end

get "/" do
  redirect "/groceries"
end

get "/groceries" do
  erb :index, locals: {
    groceries: groceries,
    filtered_letters: grocery_first_letters,
  }
end

get "/groceries/:letter" do
  letter = params[:letter]
  erb :filtered_index, locals: {
    active_letter: letter,
    filtered_letters: grocery_first_letters,
    filtered_foods: filtered_foods(letter) }
end

get "/groceries/delete/:food_id" do
  food = params[:food_id]
  sql("
    DELETE FROM groceries
    WHERE groceries.id = #{food}
  ", "exec", nil
  )

  redirect "/groceries"
end

post "/groceries" do
  new_item = params["food"]
  add_food(new_item)

  redirect "/groceries"
end
