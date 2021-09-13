class NotificationMailer < ApplicationMailer

    def notification_mail(user)
    #@user = user.email_id
    #mail to: manoj.rajendran@altiussolution.com, subject: 'Sample Email'
#byebug
    @user = user
    mail from: "sales@yantra24x7.com"

  #  mail to: @user,:subject => 'Confirmation mail from Yantra24x7 '
    mail to: @user.email_id, subject: 'You have a new notification'

  end


end
