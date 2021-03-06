require 'gmail'

class User < ActiveRecord::Base
  attr_accessible :username, :role, :activation, :account_creation_date, :birthday, :email_address, :full_name, :password_digest, :phone, :password, :password_confirmation, :tokenized_code
  validates :email_address, :full_name, :username, :phone, :presence => true
  validates :username, :uniqueness => true
  validates :email_address, :format => {
    with: %r{\w+@\w+\.com$}i,
    message: 'must be in format xxx@xxx.com'
  }
  validates :phone, :format => {
    with: %r{0[0-9][0-9][0-9][0-9][0-9][0-9][0-9]+}i,
    message: 'must be in format 0xxxxxxxx (all digits)'
  }
  
  has_many :comments, :dependent => :destroy

  has_secure_password
  after_destroy :ensure_an_admin_remains
  after_save :ensure_an_admin_remains
  before_create :set_defaults

  def add_token
    self.update_attribute("tokenized_code", Digest::MD5.hexdigest("#{self.full_name} #{self.email_address}\
      #{rand(1000).to_s} #{rand(1000).to_s} #{rand(1000).to_s}"))
  end
  
  def send_activation_email(name, account, email_address, activate_link)
    send_email(email_address, 
      "Max's Online Bookstore Account Activation",
      "Welcome to Max's Online Bookstore, #{name}. <br /> 
      Please copy the following link and paste them to the browser address bar to activate your account: <br />
      #{activate_link}",
      "<p>Welcome to Max's Online Bookstore, #{name}.</p>
        <p>You have recently registered account #{account}</p>
        <p>Please click the following link to activate your account: </p>
        <a href='#{activate_link}'> Activate Account </a>"
      )
  end

  def send_password_reset_email(reset_link)
    send_email(self.email_address, 
      "Max's Online Bookstore Password Reset",
      "Welcome to Max's Online Bookstore, #{self.full_name}. <br /> 
      Please copy the following link and paste them to the browser address bar to reset your password: <br />
      #{reset_link}",
      "<p>Welcome to Max's Online Bookstore, #{self.full_name}.</p>
        <p>You have recently requested to reset your password of account #{self.username}</p>
        <p>Please click the following link to reset your password: </p>
        <a href='#{reset_link}'> Reset Password </a>"
      )
  end

  def send_email(email_address, subj, text, html)
    unless Rails.env.test?
      gmail = Gmail.new("ngoc.nguyen@stanyangroup.com", "hongngoc92")
      gmail.deliver do
        to email_address 
        subject subj
        text_part do
          body text
        end
        html_part do
          body html
        end
      end
    end
  end
  
  def change_password(new_password)
    self.update_attribute("password", new_password)
    self.update_attribute("password_confirmation", new_password)
  end

  private
  
  def set_defaults    
    self.account_creation_date = Date.current
    self.role ||= "normal"
    self.activation ||= false
    self.tokenized_code = Digest::MD5.hexdigest("#{self.full_name} #{self.email_address} #{rand(1000).to_s} #{rand(1000).to_s} #{rand(1000).to_s}")  
  end

  def ensure_an_admin_remains
    if User.find_by_role("admin").nil?
      raise "Can't delete/downgrade the last admin"
    end
  end
end
