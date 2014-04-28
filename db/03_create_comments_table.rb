class CreateCommentsTable < Sequel::Migration
  def up
    create_table :comments do
      primary_key :id
      Fixnum :user_id
      Fixnum :wish_id
      String :body
      Time :created_at
    end
  end

  def down
    drop_table :comments
  end
end

