class UsersController < BaseController
  skip_before_filter :ensure_user_name_present, only: [:profile, :update]

  def show
    @user = User.find_by_key!(params[:id])
    unless current_user.in_same_group_as?(@user)
      flash[:error] = t("error.cant_view_member_profile")
      redirect_to dashboard_path
    end
  end

  def update
    if current_user.update_attributes(permitted_params.user)
      set_application_locale
      flash[:notice] = t("notice.settings_updated")
      redirect_to dashboard_path
    else
      @user = current_user
      @user_deactivation_response = UserDeactivationResponse.new
      flash[:error] = t("error.settings_not_updated")
      render "profile"
    end
  end

  def upload_new_avatar
    new_uploaded_avatar = params[:uploaded_avatar]

    if new_uploaded_avatar
      current_user.avatar_kind = "uploaded"
      current_user.uploaded_avatar = new_uploaded_avatar
    end

    unless current_user.save
      flash[:error] = t("error.image_upload_fail")
    end
    redirect_to profile_url
  end

  def set_avatar_kind
    @avatar_kind = params[:avatar_kind]
    current_user.avatar_kind = @avatar_kind
    current_user.save!
    redirect_to profile_url
  end

  def profile
    @user = current_user
    @user_deactivation_response = UserDeactivationResponse.new
  end

  def deactivation_instructions
    @user = current_user
    @adminable_groups = @user.adminable_groups.with_one_coordinator
  end

  def about_deactivation
  end

end
