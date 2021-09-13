class PasswordMailer < ApplicationMailer

    def password_user(user)
    #@user = user.email_id
    #mail to: manoj.rajendran@altiussolution.com, subject: 'Sample Email'
    @user = user
#    mail from: "sales@yantra24x7.com"
  #  mail to: @user,:subject => 'Confirmation mail from Yantra24x7 '
    mail to: @user.email_id, subject: 'Forgot Pawword mail from Yantra24x7'
    end

  
    def change_password(user_id, base_url)
    @user = User.find(user_id) rescue nil
    if @user.present?
        @decision_url = "#{base_url}/password"
      mail( :to => @user.email_id,
            :subject => "Change the password!")
           # mail to: "vinodhini551@gmail.com", subject: 'Forgot Pawword mail from Yantra24x7'

    end
    end

end
