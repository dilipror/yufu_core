class Statistic::Link < Statistic::Base

  def orders_count
    @user.referral_link.order_bases.count
  end

  def orders_count_percent
    orders_count.to_f / clicked_count.to_f * 100
  end

  def clicked_count
    @user.referral_link.visits.count
  end
end