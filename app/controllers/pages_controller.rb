class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :home ]

  def home
    @category = Category.new
    @categories = Category.all
  end
end
