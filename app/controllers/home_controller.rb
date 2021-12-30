class HomeController < ActionController::Base
  def top
    redirect_to "/tweets"
  end
end
