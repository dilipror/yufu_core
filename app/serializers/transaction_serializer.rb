class TransactionSerializer < ActiveModel::Serializer
  attributes :id, :sum, :isEarned, :isCommission, :date, :commission_from

  def date
    @object.creation_date
  end

  def sum
    (Currency.exchange @object.sum).to_f
  end

  def isEarned
    if @scope == @object.credit || @object.is_commission?
      return true
    end
    if @scope == @object.debit
      return false
    end

  end

  def isCommission
    @object.is_commission?
  end

  def commission_from
    if @object.is_commission?
      if @object.is_commission_from.is_a? User
        return @object.is_commission_from.email
      end
      if @object.is_commission_from.is_a? Banner
        return 'Banner'
      end
      if @object.is_commission_from.is_a? ReferralLink
        return 'Referral Link'
      end

    end
  end
end
