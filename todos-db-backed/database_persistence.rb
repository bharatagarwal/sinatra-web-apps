require 'pg'

class DatabasePersistence
  def initialize(logger)
    @db = if Sinatra::Base.production?
            PG.connect(ENV['DATABASE_URL'])
          else
            PG.connect(dbname: "todos")
          end
    @logger = logger
  end

  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end

  def find_list(id)
    sql = <<~HEREDOC
      select lists.*, 
        count(todos.id) as todos_count,
        count(nullif(todos.completed, true)) as todos_remaining_count 
      from lists
      left join todos 
      on todos.list_id = lists.id 
      where lists.id = $1
      group by lists.id
      order by lists.name;
    HEREDOC

    result = query(sql, id)
    tuple_to_list_hash(result.first)
  end

  def all_lists
    sql = <<~HEREDOC
      select lists.*, 
        count(todos.id) as todos_count,
        count(nullif(todos.completed, true)) as todos_remaining_count 
      from lists
      left join todos 
      on todos.list_id = lists.id 
      group by lists.id
      order by lists.name;
    HEREDOC

    result = query(sql)

    result.map do |tuple|
      tuple_to_list_hash(tuple)
    end
  end

  def create_new_list(list_name)
    sql = "insert into lists (name) values ($1)"
    query(sql, list_name)
  end

  def delete_list(id)
    sql = "delete from lists where id = $1"
    query(sql, id)
  end

  def update_list_name(id, new_name)
    sql = "update lists set name = $1 where id = $2"
    query(sql, new_name, id)
  end

  def create_new_todo(list_id, todo_name)
    sql = "insert into todos (name, list_id) values ($1, $2)"
    query(sql, todo_name, list_id)
  end

  def delete_todo_from_list(list_id, todo_id)
    sql = "delete from todos where list_id = $1 and id = $2"
    query(sql, list_id, todo_id)
  end

  def update_todo_status(list_id, todo_id, new_status)
    status = new_status == true ? 't' : 'f'
    
    sql = "update todos set completed = $1 where id = $2 and list_id = $3"
    query(sql, status, todo_id, list_id)
  end

  def mark_all_todos_as_completed(list_id)
    status = 't'
    sql = "update todos set completed = $1 where list_id = $2"
    query(sql, status, list_id)
  end

  # for heroku hobby plans that can only
  # take upto 20 open database connections.
  
  # def disconnect
  #   @db.close
  # end

  def find_todos_for_list(list_id)
    todos_sql = "select * from todos where list_id = $1"
    todos_result = query(todos_sql, list_id)

    todos = todos_result.map do |todo_tuple|
      { id: todo_tuple['id'].to_i,
        name: todo_tuple['name'],
        completed: todo_tuple['completed'] == 't'
      }
    end
  end

  private

  def tuple_to_list_hash(tuple)
    { id: tuple['id'].to_i,
      name: tuple['name'], 
      todos_count: tuple['todos_count'].to_i, 
      todos_remaining_count: tuple['todos_remaining_count'].to_i
    }
  end
end