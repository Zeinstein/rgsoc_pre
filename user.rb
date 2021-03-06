require 'digest/sha1'

class User < Sequel::Model

  attr_accessor :password, :password_confirmation

  set_allowed_columns :login, :password, :password_confirmation,
                      :first_name, :last_name, :email, :color

  def name
    unless first_name.empty? and last_name.empty?
      "#{last_name} #{first_name}"
    else
      "#{login}"
    end
  end

  def validate
    if new?
      if login.empty?
        errors.add(:login, "nem lehet üres")
      elsif User[:login => login]
        errors.add(:login, "már van ilyen nevű felhasználó")
      end
    end
    if new? or (not password.empty? or not password_confirmation.empty?)
      if password.empty?
        errors.add(:password, "nem lehet üres")
      end
      if password != password_confirmation
        errors.add(:password_confirmation, "nem egyezik a jelszóval")
      end
    end
    unless email.empty? or email =~ /[\w\.-]+@([\w-]+\.)+\w+/
      errors.add(:email, "nem megfelelő formátum")
    end
  end

  def before_create
    self.created_at = Time.now
    self.password_hash = Digest::SHA1.hexdigest(password)
  end

  def before_update
    unless password.empty?
      self.password_hash = Digest::SHA1.hexdigest(password)
    end
  end

  def self.authenticate(login, password)
    User[:login => login, :password_hash => Digest::SHA1.hexdigest(password)]
  end
end

