#!/bin/env ruby
# encoding: utf-8
class Users::SessionsController < Devise::SessionsController

  def new
    self.resource = build_resource(nil)
    clean_up_passwords(resource)
    respond_with(resource, serialize_options(resource))
  end

  # POST /resource/sign_in
  def create
    self.resource = warden.authenticate!(auth_options)
    set_flash_message(:notice, :signed_in) if is_navigational_format?
    sign_in(resource_name, resource)
    puts current_user
    if current_user.language == "ქართული"
      I18n.locale = 'ka'
    else
      I18n.locale = 'en'
    end
    respond_with resource, :location => after_sign_in_path_for(resource)
  end

# DELETE /resource/sign_out
  def destroy
    redirect_path = after_sign_out_path_for(resource_name)
    signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
    set_flash_message :notice, :signed_out if signed_out && is_navigational_format?

    # We actually need to hardcode this as Rails default responder doesn't
    # support returning empty response on GET request
    respond_to do |format|
      format.any(*navigational_formats) { redirect_to redirect_path }
      format.all do
        head :no_content
      end
    end
  end
end
