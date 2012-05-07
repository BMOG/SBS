module SessionsHelper

  def sign_in(user)
    cookies.permanent[:remember_token] = user.remember_token
    current_user = user
    context_initialize 
  end
  
  def signed_in?
    !current_user.nil?
  end
  
  def current_user=(user)
    @current_user = user
  end

  def current_user
    @current_user ||= user_from_remember_token
  end

  def current_user?(user)
    user == current_user
  end

  def sign_out
    Context.find_by_remember_token!(cookies[:remember_token]).delete
    current_user = nil
    cookies.delete(:remember_token)
  end

  def redirect_back_or(default)
    redirect_to(session[:return_to] || default)
    clear_return_to
  end

  def store_location
    session[:return_to] = request.fullpath
  end

  def set_current_scenario
    if not @context.scenario_id == @scenario.id then
      @context.scenario_id = @scenario.id
      @context.current_hex = @grid.central_hexagon_number
      @context.update_attributes(@context.as_json)
    end
  end

  def set_current_scale(mode)
    mode == "zoom_in" ? @context.scale *= 1.5 : @context.scale /= 1.5
    @context.update_attributes(@context.as_json)
  end 
  
  private

    def user_from_remember_token
      remember_token = cookies[:remember_token]
      User.find_by_remember_token(remember_token) unless remember_token.nil?
    end

    def clear_return_to
      session.delete(:return_to)
    end
    
    def context_initialize
      @context = Context.new
      @context.remember_token = User.find(current_user).remember_token
      @context.user_id = current_user
      @context.scale = 1
      @context.windows_width = params[:session][:width]
      @context.windows_height = params[:session][:height]
      @context.scenario_options = Hash[altitude: false, edges: false, hydrography: false, roads: false, geography: false, units: false].to_xml root: "options" 
      @context.save
    end
end