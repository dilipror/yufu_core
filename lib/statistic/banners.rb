class Statistic::Banners < Statistic::Base
  def orders_count
    Order::Base.where(:banner_id.in => @user.banner_ids).count
  end

  def orders_count_percent
    clicked = clicked_count.to_f
    return 0 if clicked == 0
    (orders_count.to_f / clicked.to_f * 100).to_i
  end

  def clicked_count
    @user.banners.inject(0) {|sum, b| sum + b.visits.count}
  end

  def pass_registration_count
    User.where(:agent_banner_id.in => @user.banners.distinct(:id)).count
  end

  def pass_registration_percent
    return 0 if clicked_count == 0
    pass_registration_count * 100  / clicked_count
  end
end