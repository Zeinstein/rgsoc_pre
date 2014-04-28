class CreateUsersTable < Sequel::Migration
  def up
    create_table :users do
      primary_key :id
      String :login
      String :password_hash
      String :first_name
      String :last_name
      String :email
      String :color
      Time :created_at
    end
  end

  def down
    drop_table :users
  end
end

