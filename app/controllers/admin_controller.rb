class AdminController < ApplicationController
  before_filter :authenticate_user!
  before_filter :requires_admin

  def requires_admin
    if current_user.role != 'admin'
      redirect_to "/"
    end
  end

  def index
    @users = User.where(:role => "user")
  end

  def manageCPVs
    profileAccount = User.where(:role => "profile").first
    @isGlobal = true
    @userID = profileAccount.id
    @cpvGroups = []
    groups = profileAccount.cpvGroups
    groups.each do |group|
      if group.id > 2
        @cpvGroups.push(group)
      end
    end
  end

end
