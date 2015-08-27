class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new

    can :read, Localization, enable: true
    can :manage, user.localizations
    can :read, user


    # can [:read, :update], Profile::Base, state: 'new'


    unless user.is_a? Admin
      can [:read, :update], Profile::Base do |profile|
        profile.can_update?
      end

      can [:read, :create], Profile::Service do |service|
        service.owner? user
      end

      can [:destroy, :update], Profile::Service do |service|
        service.can_update_and_destroy?
      end

      can [:manage], Profile::Education do |education|
        education.owner? user
      end

      can [:update, :destroy], PaymentMethod::Base do |payment_method|
        payment_method.owner? user
        # true
      end

      can :create, Order::Written::WorkReport do |report|
        report.order_written.assignee == user.profile_translator
      end
    end

    if user.is_a? Admin
      can :access, :rails_admin       # only allow admin users to access Rails Admin
      can :dashboard                  # allow access to dashboard
    end

    user.permissions.each do |permission|
      add_permission(permission)
    end

    user.groups.each do |group|
      group.permissions.each do |permission|
        add_permission(permission)
      end
    end

  end

  def add_permission(permission)
    if permission.subject_id.nil?
      if permission.subject_class.to_sym == :all
        can permission.action.to_sym, :all
      else
        can permission.action.to_sym, permission.subject_class.constantize
      end

    else
      can permission.action.to_sym, permission.subject_class.constantize, id: permission.subject_id
    end
  end

end
