class Statistic::Invites < Statistic::Base
  def count
    @user.invites.count
  end

  def clicked_count
    @user.invites.clicked.count
  end

  def clicked_percent
    return 0 if count == 0
    clicked_count * 100  / count
  end

  def pass_registration_count
    @user.invites.pass_registration.count
  end

  def pass_registration_percent
    return 0 if count == 0
    pass_registration_count * 100  / count
  end
end