class Statistic::Base
  def initialize(user)
    @user = user
  end

  def count
    nil
  end

  def orders_count
    nil
  end

  def orders_count_percent
    nil
  end

  def clicked_count
    nil
  end

  def clicked_percent
    nil
  end

  def commission
    0
  end

  def pass_registration_count
    0
  end

  def pass_registration_percent
    nil
  end
end