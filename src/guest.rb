class Guest
  attr_reader :username, :photo, :questions, :gender

  def initialize(username, photo, questions, gender)
    @username = username
    @photo = photo
    @questions = questions
    @gender = gender
  end

  def get_username
    @username.downcase.gsub("@", "")
  end
end