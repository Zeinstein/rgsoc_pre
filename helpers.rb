helpers do
  def logged_in?
    !!current_user
  end

  def current_user
    @current_user ||= User[session[:current_user_id]]
  end

  def require_user
    unless logged_in?
      session[:back_url] = request.path
      session[:error] = "Ehhez előbb be kell jelentkezned..."
      redirect "/"
    end
  end

  def form_field(label, object, attribute, type=:text)
    object_name = object.class.name.downcase
    id = "#{object_name}_#{attribute}"
    name = "#{object_name}[#{attribute}]"
    error = object.errors[attribute]
    error = %{<span class="error">#{error}</span>} if error
    if type.to_sym != :textarea && type.to_sym != :select
      %{
<p>
<label for="#{id}">#{label}:</label>
<input type="#{type}" id="#{id}" name="#{name}" value="#{object.send(attribute)}"/>
#{error}
</p>
}
    elsif type.to_sym == :textarea
      %{
<p>
<label for="#{id}">#{label}:</label> #{error}<br/>
<textarea id="#{id}" name="#{name}" rows="10" cols="60">#{object.send(attribute)}</textarea>
</p>
}
    elsif type.to_sym == :select
      %{
<p>
<label for="#{id}">#{label}:</label>
<select id="#{id}" name="#{name}">  
  <option value="green">Zöld
  <option value="blue">Kék  
  <option value="red">Piros
</select> </p>
#{error}
</p>
}
    else
      %{
<p>
Állati nagy hiba van!</p>
}
    end
  end

  def wish_li(wish)
    %{<li><a href="/wishes/#{wish.id}">#{wish.body}</a></li>}
  end

  def user_li(user)
    %{<li style=" color: #{user.color}; "><a style=" color: #{user.color}; " href="/users/#{user.id}">#{user.name}</a></li>}
  end
end

class NilClass
  def empty?
    true
  end
end

