class CreateWishesTable < Sequel::Migration
  def up
    create_table :wishes do
      primary_key :id
      Fixnum :user_id
      String :body
      Time :created_at
    end
  end

  def down
    drop_table :wishes
  end
end

