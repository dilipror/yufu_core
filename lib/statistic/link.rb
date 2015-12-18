class Statistic::Link < Statistic::Base

  def orders_count
    @user.referral_link.order_bases.count
  end

  def orders_count_percent
    clicked_count == 0 ? 0 : orders_count.to_f / clicked_count.to_f * 100
  end

  def clicked_count
    @user.referral_link.visits.count
  end

  def pass_registration_count
    @user.referral_link.invited_users.count
  end

  def pass_registration_percent
    return 0 if clicked_count == 0
    pass_registration_count * 100  / clicked_count
  end
end