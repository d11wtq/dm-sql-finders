class User
  include DataMapper::Resource

  property :id,       Serial
  property :username, String
  property :role,     String

  has n, :posts

  def post_count
    @post_count.to_i
  end
end
