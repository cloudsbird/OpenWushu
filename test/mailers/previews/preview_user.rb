# An unsaved sample member for mailer previews, so they work on an empty database.
# ?locale=id previews the Indonesian email.
module PreviewUser
  def self.call(params)
    User.new(id: 0, display_name: "Ana", email_address: "ana@example.com", password: "preview password",
             locale: params[:locale].presence_in(User::LOCALES) || "en")
  end
end
