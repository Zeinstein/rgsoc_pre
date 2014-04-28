class Comment < Sequel::Model

  set_allowed_columns :body, :wish_id, :user_id

  def validate
    if body.empty?
      errors.add(:body, "nem lehet üres")
    end
  end

  def before_create
    self.created_at = Time.now
  end
end

